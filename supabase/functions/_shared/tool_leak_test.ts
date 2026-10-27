import { assertEquals } from "jsr:@std/assert@1.0.13";
import { leaked, repaired } from "./tool_leak.ts";

Deno.test("a field the model wrote inside another one is put back, and the markup cut", () => {
  const out = {
    summary: "Hold the cut.",
    why: 'السعرات من هدفك الحالي.</why>\n<parameter name="routines">[{"name":"الجزء العلوي A","days":[0],"items":[]}]</parameter>\n<parameter name="habits">["Walk"]</parameter>',
    routines: [],
    habits: [],
    kcal: 2095,
  };
  assertEquals(leaked(out), true);
  const fixed = repaired(out);
  assertEquals(fixed.why, "السعرات من هدفك الحالي.");
  assertEquals(fixed.routines, [{ name: "الجزء العلوي A", days: [0], items: [] }]);
  assertEquals(fixed.habits, ["Walk"]);
  assertEquals(fixed.kcal, 2095);
  assertEquals(leaked(fixed), false);
});

Deno.test("a field that came back fine is kept over a leaked copy", () => {
  const fixed = repaired({ why: 'Fine.<parameter name="kcal">1</parameter>', kcal: 2000 });
  assertEquals(fixed, { why: "Fine.", kcal: 2000 });
});

Deno.test("plain answers are left alone", () => {
  const out = { summary: "Train 4 days: upper, lower, upper, lower.", habits: ["Protein at every meal, about 40 g"] };
  assertEquals(leaked(out), false);
  assertEquals(repaired(out), out);
});
