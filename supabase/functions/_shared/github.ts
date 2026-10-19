// The little of GitHub the dashboard needs: the latest run of each workflow,
// a re-run, and writing a file (the website pages). Behind an interface so
// the routes can be tested with a fake and never reach the network.

export const WORKFLOWS = ["Release", "iOS test build", "CI", "Website", "Mirror to iFynx"] as const;
export const DEFAULT_REPO = "ghassanhani/Gymco";

export type RunStatus = "passed" | "failed" | "running" | "queued";

export interface Run {
  id: number;
  name: string;
  sha7: string;
  status: RunStatus;
  when: string;
  url: string;
}

export interface GitHub {
  latestRuns(): Promise<Run[]>;
  rerun(runId: number): Promise<boolean>;
  putFile(path: string, content: string, message: string): Promise<void>;
}

export function runStatus(r: { status: string; conclusion: string | null }): RunStatus {
  if (r.status === "completed") return r.conclusion === "success" ? "passed" : "failed";
  if (r.status === "in_progress") return "running";
  return "queued";
}

type FetchFn = (url: string, init?: RequestInit) => Promise<Response>;

const toBase64 = (s: string) => btoa(String.fromCharCode(...new TextEncoder().encode(s)));

export function githubClient(opts: { token: string; repo?: string; fetchFn?: FetchFn }): GitHub {
  const repo = opts.repo ?? DEFAULT_REPO;
  const fetchFn = opts.fetchFn ?? fetch;
  const api = (path: string, init: RequestInit = {}) =>
    fetchFn(`https://api.github.com/repos/${repo}${path}`, {
      ...init,
      headers: {
        Authorization: `Bearer ${opts.token}`,
        Accept: "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent": "gymco-admin",
        ...(init.body ? { "Content-Type": "application/json" } : {}),
      },
    });

  return {
    async latestRuns() {
      const list = await api("/actions/workflows?per_page=100");
      if (!list.ok) throw new Error(`github ${list.status}`);
      const all = ((await list.json()).workflows ?? []) as { id: number; name: string }[];
      const known = WORKFLOWS.map((name) => all.find((w) => w.name === name)).filter((w): w is { id: number; name: string } => !!w);
      const runs = await Promise.all(known.map(async (w) => {
        const r = await api(`/actions/workflows/${w.id}/runs?per_page=1`);
        if (!r.ok) return null;
        const run = ((await r.json()).workflow_runs ?? [])[0];
        if (!run) return null;
        return {
          id: run.id, name: w.name, sha7: String(run.head_sha ?? "").slice(0, 7), status: runStatus(run),
          when: run.run_started_at ?? run.created_at, url: run.html_url,
        } as Run;
      }));
      return runs.filter((r): r is Run => !!r);
    },

    async rerun(runId: number) {
      const r = await api(`/actions/runs/${runId}/rerun`, { method: "POST" });
      return r.status === 201;
    },

    async putFile(path, content, message) {
      const cur = await api(`/contents/${path}`);
      const sha = cur.ok ? (await cur.json()).sha as string : undefined;
      const r = await api(`/contents/${path}`, {
        method: "PUT",
        body: JSON.stringify({ message, content: toBase64(content), ...(sha ? { sha } : {}) }),
      });
      if (!r.ok) {
        const msg = (await r.json().catch(() => ({}))).message ?? "";
        throw new Error(`github ${r.status}: ${msg}`);
      }
    },
  };
}
