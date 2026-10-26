import AppIntents
import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Lets reminders show while the app is open, too.
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // Hands Siri's requests to the app (lib/state/siri.dart).
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "GymcoSiri") {
      FlutterMethodChannel(name: "gymco/siri", binaryMessenger: registrar.messenger())
        .setMethodCallHandler { call, result in
          guard call.method == "take" else { return result(FlutterMethodNotImplemented) }
          if #available(iOS 16.0, *) { result(GymcoStore.takeQueue()) } else { result(nil) }
        }
    }
  }
}

// MARK: - Siri
//
// "Hey Siri, log water in Gymco" and the rest. Siri reads today's numbers
// from flutter.siriToday, which the app keeps current in its preferences, to
// answer out loud. What it is asked to do it keeps in its own inbox
// (gymcoSiriQueue); the app takes that over the gymco/siri channel when it
// runs and carries it out (lib/state/siri.dart).


@available(iOS 16.0, *)
enum GymcoStore {
  static let defaults = UserDefaults.standard

  static func dayKey(_ date: Date = Date()) -> String {
    let f = DateFormatter()
    f.calendar = Calendar(identifier: .gregorian)
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "yyyy-MM-dd"
    return f.string(from: date)
  }

  /// Today's numbers as the app last saw them; nil when stale or missing.
  static func today() -> [String: Any]? {
    guard let raw = defaults.string(forKey: "flutter.siriToday"),
          let data = raw.data(using: .utf8),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          json["day"] as? String == dayKey()
    else { return nil }
    return json
  }

  static let queueKey = "gymcoSiriQueue"

  static func queue() -> [[String: Any]] {
    guard let raw = defaults.string(forKey: queueKey),
          let data = raw.data(using: .utf8),
          let list = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
    else { return [] }
    return list
  }

  static func enqueue(_ action: [String: Any]) {
    if let data = try? JSONSerialization.data(withJSONObject: queue() + [action]),
       let raw = String(data: data, encoding: .utf8) {
      defaults.set(raw, forKey: queueKey)
    }
  }

  /// The queue as JSON, emptied: the app takes it when it runs.
  static func takeQueue() -> String? {
    let raw = defaults.string(forKey: queueKey)
    defaults.removeObject(forKey: queueKey)
    return raw
  }

  /// Water today: what the app last counted plus what Siri is still holding.
  static func waterToday() -> Int {
    let counted = today()?["water_ml"] as? Int ?? 0
    let waiting = queue().filter { $0["a"] as? String == "water" }.compactMap { $0["ml"] as? Int }.reduce(0, +)
    return counted + waiting
  }

  static func liters(_ ml: Int) -> String { String(format: "%.1f", Double(ml) / 1000) }
}

@available(iOS 16.0, *)
struct LogWaterIntent: AppIntent {
  static var title: LocalizedStringResource = "Log water"
  static var description = IntentDescription("Adds a drink to today's water in Gymco.")

  @Parameter(title: "Amount (ml)", default: 250, requestValueDialog: IntentDialog("How much, in millilitres?"))
  var ml: Int

  func perform() async throws -> some IntentResult & ProvidesDialog {
    let amount = max(50, min(ml, 2000))
    GymcoStore.enqueue(["a": "water", "ml": amount])
    let total = GymcoStore.waterToday()
    if let goal = GymcoStore.today()?["water_goal_ml"] as? Int, goal > 0 {
      return .result(dialog: "Added \(amount) ml. That's \(GymcoStore.liters(total)) of \(GymcoStore.liters(goal)) litres today.")
    }
    return .result(dialog: "Added \(amount) ml. That's \(GymcoStore.liters(total)) litres today.")
  }
}

@available(iOS 16.0, *)
struct CaloriesLeftIntent: AppIntent {
  static var title: LocalizedStringResource = "Calories left today"
  static var description = IntentDescription("Says how many calories and how much protein are left today.")

  func perform() async throws -> some IntentResult & ProvidesDialog {
    guard let t = GymcoStore.today(), let kcal = t["kcal_left"] as? Int else {
      return .result(dialog: "Open Gymco once today and I'll keep count for you.")
    }
    let protein = t["protein_left"] as? Int ?? 0
    if kcal >= 0 {
      return .result(dialog: "\(kcal) calories and \(max(protein, 0)) grams of protein left today.")
    }
    return .result(dialog: "You're \(-kcal) calories over today's target.")
  }
}

@available(iOS 16.0, *)
struct WeighInIntent: AppIntent {
  static var title: LocalizedStringResource = "Weigh in"
  static var description = IntentDescription("Saves today's weight in Gymco.")

  @Parameter(title: "Weight (kg)", requestValueDialog: IntentDialog("What do you weigh, in kilos?"))
  var kg: Double

  func perform() async throws -> some IntentResult & ProvidesDialog {
    guard kg >= 25, kg <= 350 else { return .result(dialog: "That doesn't look like a weight in kilos.") }
    GymcoStore.enqueue(["a": "weight", "kg": kg])
    return .result(dialog: "Saved \(String(format: "%.1f", kg)) kilos for today.")
  }
}

@available(iOS 16.0, *)
struct StartWorkoutIntent: AppIntent {
  static var title: LocalizedStringResource = "Start my workout"
  static var description = IntentDescription("Opens today's planned session in Gymco, ready to go.")
  static var openAppWhenRun = true

  func perform() async throws -> some IntentResult {
    GymcoStore.enqueue(["a": "workout"])
    return .result()
  }
}

@available(iOS 16.0, *)
struct LogFoodIntent: AppIntent {
  static var title: LocalizedStringResource = "Log food"
  static var description = IntentDescription("Writes what you ate into Gymco, to check and add.")
  static var openAppWhenRun = true

  @Parameter(title: "What you ate", requestValueDialog: IntentDialog("What did you eat?"))
  var food: String

  func perform() async throws -> some IntentResult {
    GymcoStore.enqueue(["a": "food", "text": food])
    return .result()
  }
}

@available(iOS 16.0, *)
struct GymcoShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(intent: LogWaterIntent(), phrases: [
      "Log water in \(.applicationName)",
      "Add water in \(.applicationName)",
      "I drank water in \(.applicationName)",
    ])
    AppShortcut(intent: CaloriesLeftIntent(), phrases: [
      "How many calories do I have left in \(.applicationName)",
      "Calories left in \(.applicationName)",
      "What's left today in \(.applicationName)",
    ])
    AppShortcut(intent: StartWorkoutIntent(), phrases: [
      "Start my workout in \(.applicationName)",
      "Start training in \(.applicationName)",
    ])
    AppShortcut(intent: LogFoodIntent(), phrases: [
      "Log food in \(.applicationName)",
      "Log a meal in \(.applicationName)",
    ])
    AppShortcut(intent: WeighInIntent(), phrases: [
      "Weigh in in \(.applicationName)",
      "Log my weight in \(.applicationName)",
    ])
  }
}
