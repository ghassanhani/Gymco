import { assertEquals } from "jsr:@std/assert@1.0.13";
import { githubClient, runStatus, WORKFLOWS } from "./github.ts";

type Call = { method: string; url: string; body?: unknown };

/** A fetch that answers from a table of responses and records every call. */
function fakeFetch(answers: Record<string, { status: number; body?: unknown }>) {
  const calls: Call[] = [];
  const fetchFn = (url: string, init?: RequestInit) => {
    const method = init?.method ?? "GET";
    calls.push({ method, url, body: init?.body ? JSON.parse(String(init.body)) : undefined });
    const a = answers[`${method} ${url.replace("https://api.github.com/repos/ghassanhani/Gymco", "")}`] ?? { status: 404, body: { message: "Not Found" } };
    return Promise.resolve(new Response(JSON.stringify(a.body ?? {}), { status: a.status }));
  };
  return { calls, fetchFn };
}

Deno.test("github: run status folds GitHub's states into four", () => {
  assertEquals(runStatus({ status: "completed", conclusion: "success" }), "passed");
  assertEquals(runStatus({ status: "completed", conclusion: "failure" }), "failed");
  assertEquals(runStatus({ status: "completed", conclusion: "cancelled" }), "failed");
  assertEquals(runStatus({ status: "in_progress", conclusion: null }), "running");
  assertEquals(runStatus({ status: "queued", conclusion: null }), "queued");
  assertEquals(runStatus({ status: "waiting", conclusion: null }), "queued");
});

Deno.test("github: the latest run of each known workflow, in the contract's order", async () => {
  const { calls, fetchFn } = fakeFetch({
    "GET /actions/workflows?per_page=100": {
      status: 200,
      body: { workflows: [{ id: 1, name: "CI" }, { id: 2, name: "Release" }, { id: 3, name: "Dependabot" }] },
    },
    "GET /actions/workflows/1/runs?per_page=1": {
      status: 200,
      body: { workflow_runs: [{ id: 11, head_sha: "abcdef1234567", status: "completed", conclusion: "success", run_started_at: "2026-10-20T10:00:00Z", html_url: "https://github.com/x/1" }] },
    },
    "GET /actions/workflows/2/runs?per_page=1": { status: 200, body: { workflow_runs: [] } },
  });
  const gh = githubClient({ token: "t", repo: "ghassanhani/Gymco", fetchFn });
  const runs = await gh.latestRuns();
  assertEquals(runs, [
    { id: 11, name: "CI", sha7: "abcdef1", status: "passed", when: "2026-10-20T10:00:00Z", url: "https://github.com/x/1" },
  ]);
  assertEquals(calls[0].url, "https://api.github.com/repos/ghassanhani/Gymco/actions/workflows?per_page=100");
  // Only the workflows the dashboard knows are asked for.
  assertEquals(calls.length, 3);
  assertEquals(WORKFLOWS, ["Release", "iOS test build", "CI", "Website", "Mirror to iFynx"]);
});

Deno.test("github: re-run posts to the run and reports success", async () => {
  const { calls, fetchFn } = fakeFetch({ "POST /actions/runs/11/rerun": { status: 201 } });
  const gh = githubClient({ token: "t", repo: "ghassanhani/Gymco", fetchFn });
  assertEquals(await gh.rerun(11), true);
  assertEquals(await gh.rerun(12), false);
  assertEquals(calls[0].method, "POST");
});

Deno.test("github: putting a file looks up the sha first and sends base64", async () => {
  const { calls, fetchFn } = fakeFetch({
    "GET /contents/site/support/index.html": { status: 200, body: { sha: "oldsha" } },
    "PUT /contents/site/support/index.html": { status: 200, body: { commit: { sha: "new" } } },
    "PUT /contents/site/support/ar/index.html": { status: 201, body: { commit: { sha: "new2" } } },
  });
  const gh = githubClient({ token: "t", repo: "ghassanhani/Gymco", fetchFn });
  await gh.putFile("site/support/index.html", "<p>hé</p>", "Website: support v3");
  assertEquals(calls[1].body, { message: "Website: support v3", content: btoa(String.fromCharCode(...new TextEncoder().encode("<p>hé</p>"))), sha: "oldsha" });
  // A new file has no sha to send.
  await gh.putFile("site/support/ar/index.html", "x", "Website: support v3");
  assertEquals(calls[3].body, { message: "Website: support v3", content: btoa("x") });
});

Deno.test("github: a failed put throws with GitHub's message", async () => {
  const { fetchFn } = fakeFetch({ "PUT /contents/site/x.html": { status: 422, body: { message: "bad" } } });
  const gh = githubClient({ token: "t", repo: "ghassanhani/Gymco", fetchFn });
  let msg = "";
  try {
    await gh.putFile("site/x.html", "x", "m");
  } catch (e) {
    msg = (e as Error).message;
  }
  assertEquals(msg, "github 422: bad");
});
