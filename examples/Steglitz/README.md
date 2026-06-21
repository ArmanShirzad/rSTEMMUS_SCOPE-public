
# Steglitz Example – rSTEMMUS-SCOPE Workflow

This example demonstrates a complete workflow for running **rSTEMMUS-SCOPE** using data from the **Berlin-Steglitz urban flux tower site**.

The example illustrates how to:
1. Prepare input data
2. Configure the simulation
3. Run the STEMMUS-SCOPE model
4. Evaluate model performance against observations

---

## Site Description

The Steglitz site is an **urban ecosystem observation site located in Berlin, Germany**.

Available observations include:

- Eddy covariance flux measurements
- Meteorological forcing data
- Soil moisture observations at multiple depths

These observations allow evaluation of model performance in an **urban environment**.

---

## Workflow Overview

The example consists of two main scripts:

### `roadmap.R`

This script orchestrates the full modelling workflow:

- Data ingestion
- Input preprocessing
- Model configuration
- Execution of STEMMUS-SCOPE (via MATLAB)
- Saving model outputs

### `diagnostics.R`

This script evaluates model performance by:

- Comparing simulated and observed soil moisture
- Generating diagnostic plots
- Computing performance metrics such as:

- KGE  
- R²  
- RMSE  
- MAE  

---

## Directory Structure


```
examples/Steglitz
├── README.md
├── roadmap.R
└── diagnostics.R
```
---

## How to Run the Example

1. Open the repository in **RStudio**.

2. Navigate to:

```
examples/Steglitz
```

Set the working directory:

```r
setwd("examples/Steglitz")
```

3. Run the simulation workflow:

```r
source("roadmap.R")
```
4. After the simulation completes, evaluate the results:


```r
source("diagnostics.R")
```
---

## Expected Output

Running the example will produce:

- Simulated soil moisture time series
- Observed vs simulated comparison plots
- Model performance statistics

These diagnostics help evaluate how well **STEMMUS-SCOPE reproduces observed soil moisture dynamics at Steglitz site** at the Steglitz site.

---

## Requirements

To run this example, the following software must be installed:

- **R**
- **MATLAB** (required by STEMMUS-SCOPE)
- Required R packages used in the workflow

---

## Purpose of this Example

This example demonstrates how **rSTEMMUS-SCOPE can be applied to urban ecosystem sites** and how model results can be evaluated using in-situ observations.

It provides a **reproducible workflow for running simulations and validating results** using real-world data.
