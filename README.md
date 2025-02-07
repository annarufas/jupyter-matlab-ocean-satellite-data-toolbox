[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.14193548.svg)](https://doi.org/10.5281/zenodo.14193548)

# Tools to Access Satellite Ocean Data from Main Repositories (CMEMS, OC-CCI, BICEP, EUMETSAT, NASA Ocean Color and NOAA CoastWatch)

![Data download page of well-known ocean satellite data repositories](https://github.com/user-attachments/assets/9b54e86a-1366-44d2-ba1a-2390739000ac)
*Landing page for downloading data from well-known ocean satellite data repositories.*

Are you looking to access subsets of ocean colour-related satellite data —such as chlorophyll concentration, light attenuation coefficients, euphotic layer depth, or net primary production— but dreading the time it takes to find the data in repositories and write custom download scripts? This repository simplifies the process by providing Python-based **Jupyter Notebooks** that demonstrate how to access and download ocean satellite datasets from some of the most widely used repositories:
- **[Copernicus Marine Service (CMEMS) Data Store](https://data.marine.copernicus.eu/products)**, L3 and L4 ocean colour, physical (PHYS) and biogeochemical (BGC) datasets, from merged and single sensors
- **[ESA Ocean Colour Climate Change Initiative (OC-CCI) project](https://www.oceancolour.org)**, L3 ocean colour datasets from merged sensors
- **[ESA Biological Pump and Carbon Exchange Processes (BICEP) project](https://www.bicep-project.org/Deliverables)**, L4 surface ocean carbon-based datasets
- **[EUMETSAT Data Store](https://user.eumetsat.int/data-access/data-store)**, L2 ocean colour datasets from ESA sensors
- **[NASA Ocean Color website](https://oceancolor.gsfc.nasa.gov)**, L3 ocean colour datasets from NASA sensors
- **[NOAA CoastWatch Data Portal](https://coastwatch.noaa.gov/cwn/data-access-tools/coastwatch-data-portal.html)**, L3 ocean colour datasets from single sensors

The notebooks provide examples for downloading both **time-series** and **matchup** data, guiding you through the distinct coding procedures required by each repository. The scripts are pre-configured to download datasets tailored to my research needs (area of study and type of observations), but they can be easily adapted to suit your specific research focus and dataset requirements.

Additionally, **MATLAB** scripts are included to perform minimal processing on the downloaded datasets (e.g., arranging data into a structured format for further analysis and plotting in MATLAB).

## Requirements

*⚠️ Note: These instructions are designed and tested specifically for macOS. While they may work on other operating systems (e.g., Windows or Linux), you might need to adapt the installation code accordingly.*

To use the content of this repository, ensure you have the following installed in your computer.

- Latest [**Anaconda** Python distribution](https://www.anaconda.com/) installed for your operating system, which includes **Jupyter Notebook** and the environment manager **Conda**. From Anaconda, you can launch **Jupyter Lab**, a platform that will open Jupyter Notebook in a browser window.
- [**git**](https://github.com/git-guides/install-git), which in MacOS you can install using Homebrew by typing in your terminal `brew install git`.
- [**MATLAB**](https://mathworks.com/products/matlab.html) version R2021a or later installed.
- The [ThoMaS](https://training.eumetsat.int/pluginfile.php/49380/course/section/4746/ThoMaS.pdf) toolkit (*see section "Instructions for Setting up `thomas`"*).

## Repository Structure

 - `./code/` (*provided, see "Scripts Overview"*)
    - `./jupyter/`: Jupyter Notebooks for downloading data (*provided, see section "Running the Jupyter Notebooks"*).
    - `./matlab/`: MATLAB scripts for formating data.
 - `./data/`
    - `./raw/`: raw data (`.nc` files) downloaded from source URLs using the Jupyter Notebooks (*not provided, see below for details*).
    - `./interim/`: input processed data for MATLAB scripts (*provided*).
    - `./processed/`: processed data (`.mat`) generated by MATLAB scripts (*not provided, see below for details*).
- `./resources/`
    - `./external/`: ThoMaS toolkit (*see section "Instructions for Setting up `thomas`"*).
    - `./internal/`: custom MATLAB functions generated specifically for formatting data (*provided*).

Due to large file sizes and variety of licenses that limit re-distribution of data in various ways, raw data are not hosted in the `./data/raw/` and `./data/processed/` folders. Instead, the Jupyter Notebooks offer step-by-step instructions for manually obtaining raw data (as `.nc` files), while the MATLAB scripts provide tools for processing and generating the corresponding processed datasets.

## Installing this Repository

Open your terminal and navigate to the directory where you want to put the code of this repository. Clone this repository onto your local machine by running the following command:

> `git clone https://github.com/annarufas/jupyter-matlab-ocean-satellite-data-toolbox`

## Scripts Overview

In the folder `./code/`, there are eight **Jupyter Notebooks** (`.ipynb`) to access and download time-series and matchup data and five **MATLAB** scripts (`.m`) to minimally process time-series data. Run the scripts in the following order:

| Order| Script name                     | Script action                                                                         | 
|------|---------------------------------|---------------------------------------------------------------------------------------
| 1    | downloadCMEMStimeseries.ipynb   | Notebook to download CMEMS L3 and L4 time-series BGC data (merged and single sensors) |
| 2    | downloadCMEMSmatchups.ipynb     | Notebook to download CMEMS L3 and L4 matchup BGC data (merged and single sensors)     |
| 3    | downloadOCCCItimeseries.ipynb   | Notebook to download OC-CCI L3 time-series data of ocean colour (merged sensors)       | 
| 4    | downloadOCCCImatchups.ipynb     | Notebook to download OC-CCI L3 matchup data of ocean colour (merged sensors)          |
| 5    | downloadBICEPtimeseries.ipynb   | Notebook to download BICEP L4 time-series data of surface ocean carbon                |
| 6    | downloadEUMETSATmatchups.ipynb  | Notebook to download ESA sensors L2 matchup data of ocean colour (single sensor)      |
| 7    | downloadNASAtimeseries.ipynb    | Notebook to download NASA sensors L3 time-series data of ocean colour (single sensor) |
| 8    | downloadNASAmatchups.ipynb      | Notebook to download NASA sensors L3 matchup data of ocean colour (single sensor)     |  
| 9    | main.m                          |  Main entry point for running the MATLAB functions below (*make sure Notebooks 1, 3, 5 and 7 have been run before executing*) |
| 10   | ncreadCMEMStimeseries.m         | MATLAB function that arranges downloaded CMEMS time-series data                               | 
| 11   | ncreadOCCCItimeseries.m         | MATLAB function that arranges downloaded OC-CCI time-series data                              | 
| 12   | ncreadBICEPtimeseries.m         | MATLAB function that arranges downloaded BICEP time-series data                               |
| 13   | ncreadNASAtimeseries.m          | MATLAB function that arranges downloaded NASA time-series data                                |

## Running the Jupyter Notebooks

To run the Python-based Jupyter Notebooks, you will need to set up four isolated Python environments using Conda. These environments are:
- `bashenv`: for processing Bash commands in Jupyter Notebooks
- `copernicusmarine`: for using the Copernicus Marine Toolbox
- `thomas`: for EUMETSAT matchups

An **environment** consists of a specific Python version and various packages. The two most popular tools for setting up environments are **PIP** and **Conda**. There exist two free **installers of Conda**:
- **Anaconda**. Requires about 3 GB disk space, and it installs over 150 scientific packages (for example, packages for statistics and machine learning). It also sets up the Anaconda Navigator, a GUI tool that helps you manage Conda environments and packages.
- **Miniconda**. Requires about 400 MB disk space, and it contains only a few basic packages. 

When you install Anaconda, you get two things: the Conda (the package and environment management system), and the so-called “root environment”. Then, Conda creates a root environment that contains two things: a certain version of Python, and some basic packages. Besides the root environment, you can create as many additional environments as you want. These additional environments can contain different versions of Python and different packages.

If you are new to Python, I recommend the [Python for Atmosphere and Ocean Scientists repository](https://github.com/carpentrieslab/python-aos-lesson), with examples on how to create environments and use Anaconda.

### Instructions for Setting up `bashenv`

`bashenv` is an environment that will allow us to execute Bash commands in Jupyter Notebooks. By default, Jupyter Notebook does not come with Bash installed. Therefore, to use Bash commands in Jupyter Notebook, you need to install the Bash kernel. Here is how to do it.

1. Create an environment containing the package `bash_kernel`. In your terminal, type the following:

> `conda create --name bashenv python=3.11 jupyterlab bash_kernel`

2. Activate the newly created conda environment.

> `conda activate bashenv`

3. Install `nb_conda_kernels` in your base environment if not done yet. `nb_conda_kernels` provides all the kernels to Jupyter Lab.

> `conda install -n base -c conda-forge nb_conda_kernels`

4. Install all dependencies needed to use Jupyter Lab. The `ipykernel` module is necessary to use a conda environment as a kernel in Jupyter Lab. Install it in your active conda environment using the following command:

> `conda install ipykernel`

5. Register the conda environment as a Jupyter kernel to use the environment within Jupyter Lab.

> `ipython kernel install --user --name=bashenv --display-name="bashenv"`

Which prompts: *Installed kernelspec bashenv in /Users/Anna/Library/Jupyter/kernels/bashenv.*

Recommended to use the same kernel name as the environment name here (i.e. 'bashenv' in this example).

6. Launch `jupyter-lab`. In your terminal, type `jupyter-lab` (alternatively, launch it from Anaconda), which will launch Jupyter Lab in a browser window. Once Jupyter Lab is open, you can select your conda environment as your kernel. To do this, click on ‘Kernel’ > ‘Change kernel’ > 'bashenv'.

### Instructions for Setting up `copernicusmarine`

The [Copernicus Marine Toolbox](https://help.marine.copernicus.eu/en/articles/7949409-copernicus-marine-toolbox-introduction) is the tool necessary to download any product from the [Copernicus Marine Data Store](https://data.marine.copernicus.eu/products) as of March 2024. These instructions, based on the Copernicus Marine Toolbox [installation guide](https://help.marine.copernicus.eu/en/articles/7970514-copernicus-marine-toolbox-installation), will install in your machine the Copernicus Marine Toolbox python environment, `copernicusmarine`, and will set you up using the python environment in Jupyter Lab, a platform that will open Jupyter Notebooks in a browser window.

1. Create the `copernicusmarine` conda environment.

> `conda create --name copernicusmarine conda-forge::copernicusmarine --yes`

2. Activate the conda environment.

> `conda activate copernicusmarine`\
> `conda env list && copernicusmarine --help`

3. Retrieve a description of available datasets in the Copernicus Marine Data Store. Run the following command, which will create a catalog of available datasets for further use or reference:

> `copernicusmarine describe --overwrite-metadata-cache > CMEMS_catalog_240420.json`

That file is stored in this repository under `./doc`.

5. Install `openpyxl` to handle Excel files.

> `conda install openpyxl`

4. Follow steps 4–6 as in section "Instructions for setting up `bashenv`".

### Instructions for Setting up `thomas`

[EUMETSAT's Data Store](https://eumetsatspace.atlassian.net/wiki/spaces/DSDS/pages/315785276/Accessing+the+Data+Store) offers different [ways](https://eumetsatspace.atlassian.net/wiki/spaces/DSDS/pages/315818088/Using+the+APIs) to access and interact with their data in order to refine searches. Many of those are supported by the EUMETSAT Data Access Client [`eumdac`](https://eumetsatspace.atlassian.net/wiki/spaces/DSDS/pages/2016280587/Using+EUMDAC). We are going to use [`eumdac`](https://eumetsatspace.atlassian.net/wiki/spaces/EUMDAC/overview) to access, subset and download L2 data for matchups. EUMETSAT has created the [ThoMaS](https://training.eumetsat.int/pluginfile.php/49380/course/section/4746/ThoMaS.pdf) (Tool to generate Matchups of OC products with Sentinel-3/OLCI) toolkit for automating Sentinel-3 OLCI ocean colour data acquisition and matchup analysis. It is an automated (API) method to search for and retrieve products. You will need to downlaod ThoMaS and place it in the `./resources/external/` directory. There are two ways to download it. Either the Git way:

> `cd ./resources/external/`\
> `mkdir ThoMaS`\
> `cd ThoMaS`\
> `git clone --depth=1 https://gitlab.eumetsat.int/eumetlab/oceans/ocean-science-studies/ThoMaS`

or directly downloading the code from the git repository, at

> `https://gitlab.eumetsat.int/eumetlab/oceans/ocean-science-studies/ThoMaS`

To create the ThoMaS Conda environment, follow these steps:

1. In your terminal, type the following:

> `cd ./resources/external/ThoMaS/`\
> `conda env create -f environment.yml -n thomas`\
> `conda activate thomas`

2. Follow steps 4–6 as in section "Instructions for setting up `bashenv`".

3. Obtain EUMETSAT's consumer key and secret. In the EUMETSAT Data Store, create an EO Portal user and get API keys (consumer_key,consumer_secret). These are fixed for each user.

## Acknowledgments

This work was conducted as part of my postdoctoral research project at the University of Oxford with the Agile Initiative and funded by the Natural Environment Research Council (NERC) grant NE/W004976/1. I would also like to acknowledge the invaluable support from the Copernicus Marine Service helpdesk officers and the training provided during the 2023 Trevor Platt Science Foundation (TPSF) Symposium. My thanks also extend to EUMETSAT for their financial support, which enabled me to attend the TPSF Symposium, and to the Lockey Fund at the University of Oxford for additional funding.

