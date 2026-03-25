/**
 * AssignmentVerifier - Client-side circuit auto-verification engine
 *
 * Runs test cases against the current circuit in the simulator,
 * collecting pass/fail results and submitting them to the server.
 *
 * Usage:
 *   const verifier = new AssignmentVerifier(testCases, assignmentId, projectId);
 *   const results = await verifier.runAllTests();
 *   await verifier.submitResults();
 */
class AssignmentVerifier {
  constructor(testCases, assignmentId, projectId) {
    this.testCases = testCases;
    this.assignmentId = assignmentId;
    this.projectId = projectId;
    this.results = [];
    this.running = false;
  }

  async runAllTests() {
    if (this.running) return this.results;
    this.running = true;
    this.results = [];

    this.dispatchEvent("verification:started", { total: this.testCases.length });

    for (let i = 0; i < this.testCases.length; i++) {
      const testCase = this.testCases[i];
      const result = await this.runSingleTest(testCase);
      this.results.push(result);

      this.dispatchEvent("verification:progress", {
        current: i + 1,
        total: this.testCases.length,
        result: result
      });
    }

    this.running = false;
    this.dispatchEvent("verification:completed", { results: this.results });
    return this.results;
  }

  async runSingleTest(testCase) {
    try {
      // 1. Set input probe values
      const missingProbes = [];
      Object.entries(testCase.inputs).forEach(([probeName, value]) => {
        const probe = globalScope.findInput(probeName);
        if (probe) {
          probe.setOutput(value);
        } else {
          missingProbes.push(probeName);
        }
      });

      if (missingProbes.length > 0) {
        return this.buildResult(testCase, "failed", {},
          `Missing input probes: ${missingProbes.join(", ")}`);
      }

      // 2. Run simulation — sequential circuits need more cycles
      const cycles = testCase.sequential ? 50 : 10;
      await this.simulateAndWait(cycles);

      // 3. Read output probe values
      const actualOutputs = {};
      let hasUnstable = false;

      Object.keys(testCase.expected_outputs).forEach((probeName) => {
        const probe = globalScope.findOutput(probeName);
        if (probe) {
          const value = probe.getValue();
          actualOutputs[probeName] = value;
          // Check for oscillating/undefined outputs
          if (value === undefined || value === null) hasUnstable = true;
        } else {
          actualOutputs[probeName] = null;
          missingProbes.push(probeName);
        }
      });

      if (missingProbes.length > 0) {
        return this.buildResult(testCase, "failed", actualOutputs,
          `Missing output probes: ${missingProbes.join(", ")}`);
      }

      if (hasUnstable) {
        return this.buildResult(testCase, "unstable", actualOutputs,
          "Circuit output did not stabilize after simulation");
      }

      // 4. Compare actual vs expected
      const passed = Object.entries(testCase.expected_outputs).every(
        ([key, expected]) => actualOutputs[key] === expected
      );

      return this.buildResult(
        testCase,
        passed ? "passed" : "failed",
        actualOutputs
      );

    } catch (error) {
      return this.buildResult(testCase, "failed", {},
        `Runtime error: ${error.message}`);
    }
  }

  buildResult(testCase, status, actualOutputs, errorMessage = null) {
    return {
      test_case_id: testCase.id,
      name: testCase.name,
      status: status,
      passed: status === "passed",
      actual_outputs: actualOutputs,
      expected_outputs: testCase.expected_outputs,
      points: testCase.points,
      error: errorMessage,
      verified_at: new Date().toISOString()
    };
  }

  async simulateAndWait(cycles) {
    return new Promise((resolve) => {
      let count = 0;
      const interval = setInterval(() => {
        if (typeof play === "function") play();
        count++;
        if (count >= cycles) {
          clearInterval(interval);
          resolve();
        }
      }, 10);  // 10ms per cycle = 500ms max for sequential
    });
  }

  async submitResults() {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;

    const response = await fetch(
      `/assignments/${this.assignmentId}/projects/${this.projectId}/verify`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken
        },
        body: JSON.stringify({ results: this.results })
      }
    );

    if (!response.ok) {
      throw new Error(`Verification submission failed: ${response.status}`);
    }

    return response.json();
  }

  getSummary() {
    const passed = this.results.filter(r => r.status === "passed").length;
    const failed = this.results.filter(r => r.status === "failed").length;
    const unstable = this.results.filter(r => r.status === "unstable").length;
    const total = this.results.length;

    const earnedPoints = this.results
      .filter(r => r.status === "passed")
      .reduce((sum, r) => sum + r.points, 0);
    const totalPoints = this.results
      .reduce((sum, r) => sum + r.points, 0);

    return {
      passed, failed, unstable, total,
      earnedPoints, totalPoints,
      percentage: totalPoints > 0
        ? Math.round((earnedPoints / totalPoints) * 100)
        : 0
    };
  }

  dispatchEvent(name, detail) {
    if (typeof window !== "undefined") {
      window.dispatchEvent(new CustomEvent(name, { detail }));
    }
  }
}

export default AssignmentVerifier;
