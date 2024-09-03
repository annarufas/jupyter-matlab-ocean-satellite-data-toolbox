# Tools to access, download and minimally process remote sensing data from main repositories

This repository contains a collection of python-based **Jupyter Notebooks** to demonstrate how to access and download satellite-based datasets from [OC-CCI (Ocean Colour Climate Change Initiative)](https://www.oceancolour.org), [Biological Pump and Carbon Exchange Processes (BICEP)](https://www.bicep-project.org/Deliverables), [Copernicus Marine Service (CMEMS)](https://data.marine.copernicus.eu/products), [EUMETSAT](https://user.eumetsat.int/data-access/data-store) and [NASA's ocean color website](https://oceancolor.gsfc.nasa.gov) both for time-series and matchup data. They show generic steps to download data from tose repositories, each of which has its own procedure. The scripts are set to download specific datasets of my choice, with names specified in the first cell in the scripts. Just changed the names to whatever suits you. Matlab scripts are also provided to minimally process those datasets.

## Requirements

To use the content of this repository, ensure you have the following.

- Latest [Anaconda Python distribution](https://www.anaconda.com/) installed for your operating system, which includes Jupyter Notebooks and the environment manager Conda. From Anaconda, we can launch JupyterLab, a platform that will open Jupyter Notebooks in a browser window.
- [git](https://github.com/git-guides/install-git), which in MacOS you can install using Homebrew by typing in your terminal `brew install git`.
- MATLAB version R2021a or later installed. 

## Installing this repository

Open your terminal and navigate to the directory where you want to put the code of this repository. Clone this repository onto your local machine by running the following command:

`git clone https://github.com/annarufas/python-matlab-satellitedata-scripts.git`

## Available scripts in the folder `./code`

The following scripts have been run in this order to analyse the data and reproduce the figures in our paper.

| Num| Script name                           | Script action                                                |
|----|---------------------------------------|--------------------------------------------------------------
| 1  | downloadBICEPtimeseries.ipynb         | JupyterNotebook to access and download BICEP L3 timeseries data |
| 2  | downloadCMEMSmatchupsCMT.ipynb        | JupyterNotebook to access and download CMEMS L3 matchup data    |
| 3  | downloadCMEMStimeseriesCMT.ipynb      | JupyterNotebook to access and download CMEMS L3 timeseries data |
| 4  | downloadEUMETSATmatchupsThoMaS.ipynb  | JupyterNotebook to access and download EUMETSAT L2 matchup data    |
| 5  | downloadNASAmatchups.ipynb            | JupyterNotebook to access and download NASA L2 matchup data                 | 
| 6  | downloadNASAtimeseries.ipynb          | JupyterNotebook to access and download NASA timeseries data          |
| 7  | downloadOCCCImatchups.ipynb           | JupyterNotebook to access and download OC-CCI matchup data           |
| 8  | downloadOCCCItimeseries.ipynb         | JupyterNotebook to access and download OC-CCI timeseries data        |       
| 9  | ncreadTimeseriesBicepData.m           | Matlab script to minimally process downloaded BICEP timeseries data  |
| 10 | ncreadTimeseriesCmemsData.m           | Matlab script to minimally process downloaded BICEP timeseries data
| 11 | ncreadTimeseriesNasaData.m            | Matlab script to minimally process downloaded BICEP timeseries data
| 12 | ncreadTimeseriesOccciData.m           | Matlab script to minimally process downloaded BICEP timeseries data



## Running the Jupyter Notebooks

To run the python-based Jupyter Notebooks, you will need setting up a collection of four isolated python environments using conda. You will set up four environments:
- `bashenv`: for processing Bash commands in Jupyter Notebooks
- `copernicusmarine`: for using Copernicus Marine Toolbox
- `thomas`: for EUMETSAT matchups

An **environment** consists of a certain Python version and some packages. The two most popular tools for setting up environments are **PIP** and **Conda**. There exist two free **installers of Conda**: **Anaconda**, which requires about 3 GB disk space, and it installs over 150 scientific packages (for example, packages for statistics and machine learning). It also sets up the Anaconda Navigator, a GUI tool that helps you manage Conda environments and packages, and **Miniconda**, requires about 400 MB disk space, and it contains only a few basic packages. Anaconda sets up on your computer two things: the Conda (the package & environment management system), and the so-called “root environment”. Then, Conda creates a root environment that contains two things: a certain version of Python, and some basic packages. Besides the root environment, you can create as many additional environments as you want. These additional environments can contain different versions of Python and different packages.

### Instructions for setting up `bashenv`

`bashenv` is an environment that will allow us to execute Bash commands in JupyterNotebooks. By default, Jupyter Notebook does not come with Bash installed. To use Bash commands in Jupyter Notebook, you need to install the Bash kernel. Here’s how to do it.

1. Create an environment containing the package `bash_kernel`.

In your terminal, type the following:

`conda create --name bashenv python=3.11 jupyterlab bash_kernel`

2. Activate the newly created conda environment.

`conda activate bashenv`

3. Install `nb_conda_kernels` (if not done yet).

You need to install `nb_conda_kernels` in your base environment if not done yet. `nb_conda_kernels` provides all the kernels to Jupyter Lab.

`conda install -n base -c conda-forge nb_conda_kernels`

4. Install all dependencies needed to use Jupyter Lab.

The `ipykernel` module is necessary to use a conda environment as a kernel in Jupyter Lab. Install it in your active conda environment using the following command:

`conda install ipykernel`

5. Register the conda environment as a Jupyter kernel to use the environment within Jupyter Lab.

`ipython kernel install --user --name=bashenv --display-name="bashenv"`

Which prompts: *Installed kernelspec bashenv in /Users/Anna/Library/Jupyter/kernels/bashenv.*

Recommended to use the same kernel name as the environment name here (i.e. 'bashenv' in this example).

6. Launch `jupyter-lab`.

In your terminal, type `jupyter-lab` (alternatively, launch it from Anaconda), which will launch Jupyter Lab in a browser window. Once Jupyter Lab is open, you can select your conda environment as your kernel. To do this, click on ‘Kernel’ > ‘Change kernel’ > 'bashenv'.

### Instructions for setting up `copernicusmarine`

The [Copernicus Marine Toolbox](https://help.marine.copernicus.eu/en/articles/7949409-copernicus-marine-toolbox-introduction) is the tool necessary to download any product from the [Copernicus Marine Data Store](https://data.marine.copernicus.eu/products) as of March 2024. These instructions, based on the Copernicus Marine Toolbox [installation guide](https://help.marine.copernicus.eu/en/articles/7970514-copernicus-marine-toolbox-installation), will install in your machine the Copernicus Marine Toolbox python environment, `copernicusmarine`, and will set you up using the python environment in Jupyter Lab, a platform that will open Jupyter Notebooks in a browser window.

1. Create the `copernicusmarine` conda environment.

`conda create --name copernicusmarine conda-forge::copernicusmarine --yes`

2. Activate the conda environment.

`conda activate copernicusmarine`\
`conda env list && copernicusmarine --help`

3. Retrieve a description of available datasets in the Copernicus Marine Data Store. 

Run the following command, which will create a catalog of available datasets for further use or reference:

`copernicusmarine describe --overwrite-metadata-cache > CMEMS_catalog_240420.json`

That file is in `./doc`.

5. Install `openpyxl` to handle Excel files.

`conda install openpyxl`

4. Follow steps 4–6 as in section "Instructions for setting up `bashenv`".

### Instructions for setting up `thomas`

[EUMETSAT's Data Store](https://eumetsatspace.atlassian.net/wiki/spaces/DSDS/pages/315785276/Accessing+the+Data+Store) offers different [ways](https://eumetsatspace.atlassian.net/wiki/spaces/DSDS/pages/315818088/Using+the+APIs) to access and interact with the data in order to refine searches. Many of those are supported by the EUMETSAT Data Access Client [`eumdac`](https://eumetsatspace.atlassian.net/wiki/spaces/DSDS/pages/2016280587/Using+EUMDAC). We are going to use [`eumdac`](https://eumetsatspace.atlassian.net/wiki/spaces/EUMDAC/overview) to access, subset and download L2 data for matchups. EUMETSAT has created the [ThoMaS](https://training.eumetsat.int/pluginfile.php/49380/course/section/4746/ThoMaS.pdf) (Tool to generate Matchups of OC products with Sentinel-3/OLCI) toolkit for automating OLCI ocean colour data acquisition and match-up analysis. It is an automated (API) method to search for and retrieve products. You will need to downlaod ThoMaS. Once downloaded, please place it in the `./resources/external/` directory. There are two ways to download it. Either the Git way:

`cd ./code/internal/`

`mkdir ThoMaS`

`cd ThoMaS`

`git clone --depth=1 https://gitlab.eumetsat.int/eumetlab/oceans/ocean-science-studies/ThoMaS`

or directly downloading the code from the git repository, at

`https://gitlab.eumetsat.int/eumetlab/oceans/ocean-science-studies/ThoMaS`

To create the ThoMaS conda environment, follow these steps:

1. In your terminal, type the following:

`cd ./code/internal/ThoMaS/`

`conda env create -f environment.yml -n thomas`

`conda activate thomas`

2. Follow steps 4–6 as in section "Instructions for setting up `bashenv`".

3. Obtain EUMETSAT's consumer key and secret. In the EUMETSAT Data Store, create an EO Portal user and get API keys (consumer_key,consumer_secret). These are fixed for each user.


## Author

* [**Anna Rufas**](mailto://Anna.RufasBlanco@earth.ox.ac.uk)

## Acknowledgments

This work was completed as part of my postdoctoral research project at the University of Oxford. under the NERC grant NE/W004976/1 as part of the Agile Initiative at the Oxford Martin School. 

