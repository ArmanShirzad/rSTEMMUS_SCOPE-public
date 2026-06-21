# Compliance & Best Practices 

This document outlines how the `rSTEMMUS_SCOPE` repository and its recent contributions align with **FAIR principles**, **GDPR compliance**, and the **EU AI Act**.

---

## 1. FAIR Principles (Findable, Accessible, Interoperable, Reusable)

The repository's architecture and recent updates strongly support FAIR scientific data management:

*   **Findable:** 
    *   Simulation outputs are automatically stamped with timestamps, site names, and precise configurations (via `run_inMATLAB.R`).
    *   The newly integrated `run_metadata.json` clearly documents the OS, R version, Octave/MATLAB version, and execution duration for every single run, making individual simulations highly discoverable.
*   **Accessible:** 
    *   The transition to support **GNU Octave** ensures that anyone without a commercial MATLAB license can easily run the model.
    *   Parameters are natively defined in open-source R standard formats before translation to engine configurations.
*   **Interoperable:** 
    *   Output processing uses the new `recover_csv.m` helper to translate proprietary `.mat` arrays into standard, machine-readable `CSV` formats that can be parsed by any open-source data science stack (Python, Julia, R).
*   **Reusable:** 
    *   The parallelization fix (removing `path.txt`) now completely isolates runs, guaranteeing that researchers can reproduce simulations concurrently without data corruption.

---

## 2. GDPR Compliance (Data Privacy)

*   **No Personal Data Processing:** The `rSTEMMUS_SCOPE` model processes physical, meteorological, and vegetation data (e.g., soil moisture, LAI, weather stations). It does not collect, process, or store Personally Identifiable Information (PII).
*   **Local Execution:** The codebase is designed to run locally or on sovereign HPC clusters. No telemetry, user tracking, or background analytics are sent to remote servers during execution (`run_simulation_background.sh` outputs purely to local logs).
*   **Explicit Output Locations:** Data is written strictly to user-defined `output/` directories, preventing accidental data sprawling across user systems.

---

## 3. EU AI Act Alignment

While `rSTEMMUS_SCOPE` is a deterministic physical/mathematical model rather than a generative AI or machine learning model, its ecosystem adheres to the transparency principles outlined in the EU AI Act:

*   **Explainability:** The model solves known physical equations (Richards' equation, Energy balance). It does not employ "black box" prediction mechanisms.
*   **Traceability:** The addition of `run_metadata.json` ensures that every simulation has a clear audit trail.
*   **Open Access to Logic:** The source code for calculation (`src/`) is entirely open and auditable by scientific peers and regulators.

---

## 4. Sharing with Lab Partners & Collaboration Protocol

To effectively share this repository containing the new parallelized Octave changes and maintain a clean workflow among lab partners, please follow this protocol:

### A. Initial Setup for Lab Partners
1. Have your partners clone the lab's origin repository:
   ```bash
   git clone https://github.com/ArmanShirzad/rSTEMMUS_SCOPE.git
   ```
2. By default, the clone will track the `feature/octave-compatibility-fix` branch (set as default).

### B. Tracking Corporate Upstream
If partners need to pull updates from the original corporate repository:
```bash
git remote add upstream https://github.com/EcoExtreML/rSTEMMUS_SCOPE.git
git fetch upstream
```

### C. Contributing New Changes
When a lab partner wants to add a new feature or experiment:
1. Create a new branch: `git checkout -b feature/their-new-experiment`
2. Commit changes and push to the lab repository: `git push -u origin feature/their-new-experiment`
3. Open a Pull Request on the lab's GitHub page.

This ensures the `feature/octave-compatibility-fix` branch remains stable for continuous parallel execution while the team collaborates.
