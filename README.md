# Automated EEG Preprocessing Pipeline

This repository contains MATLAB functions that automate specific preprocessing steps for (continuous) EEG recordings using EEGLAB (Delorme & Makeig, 2004). 

## Table of Contents
1. [General Information](#automated-eeg-preprocessing-pipeline)

   ​	[Central Features](#central-features)

   ​	[Before Running The Pipeline](#before-running-the-pipeline)

   ​	[After Running The Pipeline (Limitations)](#after-running-the-pipeline-limitations)

2. [Getting Started](#getting-started)

3. [Usage of pipeline_wrapper.m](#usage)

   ​	[Inputs](#inputs)

   ​	[Outputs](#outputs)

   ​	[Example Usage](#example-usage)

4. [Pipeline Workflow](#pipeline-workflow)

5. [Dependencies](#dependencies)

6. [Important Notes](#important-notes)

7. [References](#references)

---

## General Information

### Central Features

- **Workflow:** Handles (**1**) high-pass filtering (HP fltering), (**2**) bad channel detection, rejection, and interpolation, as well as (**3**) ICA-based (Independent Component Analysis) artifact removal in a single call via pipeline_wrapper.m.
- **Double Filtering for better ICA results:**
  - **0.1 Hz high-pass** for the final data (preserves low frequency components in the EEG signal).
  - **1.0 Hz high-pass** for ICA training. This strong HP-filter improves  the quality of Artifact Subspace Reconstruction (ASR) and ICA (see *Winkler et al., 2015*).
- **Artifact Removal:** Combines **ASR**  and **ICA**  with ICLabel to identify and remove eye-movement-related components.
- **Data Preservation:** The pipeline works with continuous data. Importantly, **no time points are removed**. Thus, the original time structure is fully maintained.

### Before Running The Pipeline

The following steps might be performed **before** running this pipeline (e.g., via an initial preparation script):

1. **Downsampling:** Reduce the sampling rate (e.g., to 250 Hz or 500 Hz) to speed up ICA and ASR.
2. **Initial Referencing:** When using reference-free systems like BioSemi (see https://www.biosemi.com/faq/cms&drl.htm), an initial reference should be computed.
3. **Data Selection:** If the EEG data includes non-releavnt recording periods (e.g., breaks), crop the data to focus the ICA on task-relevant signal.

### After Running The Pipeline (Important Limitations)

Please note, this pipeline exclusively focuses on HP-filtering, cleaning of eye-movement-related artifacts, and channel interpolation. The following steps are **not** included and must be performed separately:

- **Re-referencing:** Re-referecning the data to the average reference or the mastoid, otherwise the data remains in its original reference (or the reference set during the "Pre-Pipeline" phase). 
- **Epoching:**  Segmentation around events of interest must be done after the pipeline.
- **Artifact Rejection:** Manual or automatic deletion of bad time segments (e.g., extreme voltage fluctuations).

------

## Getting Started

To run the preproceessing pipeline, add the repository and its subfolders to your MATLAB path and call pipeline_wrapper.m.  

------

## Usage of pipeline_wrapper.m

Matlab

```
EEG = pipeline_wrapper(filename, filepath, chanlocs)
```

### Inputs

| **Argument**   | **Type**      | **Description**                                              |
| -------------- | ------------- | ------------------------------------------------------------ |
| **`filename`** | *String*      | The name of the EEG set file to load (e.g., `'subject01.set'`). |
| **`filepath`** | *String*      | The full directory path where the file is located.           |
| **`chanlocs`** | *Struct/Path* | The channel location structure (or file path).               |

### Outputs

| **Argument** | **Type** | **Description**                                              |
| ------------ | -------- | ------------------------------------------------------------ |
| **`EEG`**    | *Struct* | The final preprocessed EEGLAB structure containing continuous HP-filtered data, without eye-movement-related artifacts and interpolated channels. Moreover, the artifact information is saved inside the EEGlab structure (e.g., number of interpolated channels) |


### Example Usage

Matlab

```
% Define file parameters
fName = 'sub-01_task-rest_eeg.set';
fPath = 'C:\Data\Raw\';

% Load your standard channel locations
load('standard_chanlocs.mat'); % Assumes variable is named 'chanlocs'

% Run the pipeline
cleaned_EEG = pipeline_wrapper(fName, fPath, chanlocs);

% Save the result
pop_saveset(cleaned_EEG, 'filename', 'sub-01_cleaned.set', 'filepath', 'C:\Data\Preprocessed\');
```

---

## Pipeline Workflow

The wrapper executes the following steps:

1. **Initialization:** Loads set file into EEGlab.
2. **Basic Filtering:** Applies a **0.1 Hz high-pass filter** and removes **50 Hz line noise**.
3. **Bad Channel Detection:** Statistically identifies and marks abnormal channels (threshold: 3.29 SD) based on their probability, kurtosis, and spectral properties.
4. **Strict HP-Filtering (for ICA):**
   - Creates a temporary copy of the data.
   - Removes bad channels.
   - Applies a **strict 1.0 Hz high-pass filter** to optimize the data for subsequent ICA.
5. **ASR Cleaning:** Runs **Artifact Subspace Reconstruction** on the  1 Hz-filtered data to remove high-amplitude artifacts. Importantly, frontal electrodes (e.g., 'Fp1','Fpz','Fp2', etc.) which might be affected by eye-movement-related artifacts are temporarily discarded based on their channel coordinates. This step is introduced to prevent eye-movement artifacts from being excluded prior to the ICA.
6. **ICA Decomposition:** Performs ICA and automatically identifies eye-movement-related components (i.e., blinks and saccades) via IClabel (Pion-Tonachini et al., 2019).
7. **Weight Transfer:**
   - Transfers the calculated ICA weights back to the **original 0.1 Hz filtered data**.
   - Subtracts the identified artifact components.
8. **Interpolation:** Spherical spline interpolation is applied to reconstruct the previously removed bad channels using the provided `chanlocs`.
9. **Cleanup:** Deletes ICA weights (`icaact`, `icawinv`, etc.) to minimize file size.
10. **Metadata:** Appends processing history to `EEG.etc.artifact_info`.

------

## Dependencies

To run this wrapper, ensure **EEGLAB** and following custom functions are on your MATLAB path:

- `hp_notch_filter`
- `bad_channels`
- `select_set` (Custom set selection utility: part of this repository)
- `ASR_before_ICA`
- `automatedICA`
- `transfer_remove_ICA`
- `spline_interpolation`
- `artifact_info`

------

## Important Notes

1. **Removing informations about ICA :** To reduce the size of the resulting set files, ICA-related infos like `EEG.icaweights`, `EEG.icaact`, etc., are removed. If you want to inspect ICA components manually, comment out the "Delete ICA results" section in the code.
2. **Further Processing:** As already noted, re-referencing (e.g., to average reference), epoching and artifact rejection have to be performed **after** this pipeline.

## References

> Delorme, A., & Makeig, S. (2004). EEGLAB: an open source toolbox for analysis of single-trial EEG dynamics including independent component  analysis. *Journal of Neuroscience Methods*, *134*(1), 9–21. https://doi.org/10.1016/j.jneumeth.2003.10.009
>
> Pion-Tonachini, L., Kreutz-Delgado, K., & Makeig, S. (2019).  ICLabel: An automated electroencephalographic independent component  classifier, dataset, and website. *NeuroImage*, *198*, 181–197. https://doi.org/10.1016/j.neuroimage.2019.05.026
>
> Winkler, I., Debener, S., Muller, K., & Tangermann, M. (2015). On  the influence of high-pass filtering on ICA-based artifact reduction in  EEG-ERP. *37th Annual International Conference of the IEEE Engineering in Medicine and Biology Society*, *2015*, 4101–4105. https://doi.org/10.1109/embc.2015.7319296