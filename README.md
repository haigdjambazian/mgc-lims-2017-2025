# README

### Clarity related repository data
* Successive xml/txt files that carry Basespace Clarity LIMS configuration changes. (config_slicer)
* Lims workflow code created at McGill that runs inside Clarity LIMS. (customextentions)
### Downstream run processing and analysis code
* Illumina run processing code and associated config files that runs on the abacus cluster. (runprocessing)
* Nanopore run processing code and associated config files that runs on the abacus cluster. (runprocessing)
* MGI run processing code and associated config files that runs on the abacus cluster. (runprocessing)
* Run monitoring code that manages Illumina/MGI/Nanopore.
### Deploying the system (Clarity + run monitoring/processing):
* See INSTALLATION.md for Clarity LIMS 5.2 and python packages. 
* The xml configs in config_slicer need to be applied followed by the transfer of customextentions code.
* The processing pipeline is dependent on bcl2fastq, mugqic modules and the availability of a compute cluster.
* Copy runprocessing folder to lims agent home.
* Follow startup instructions for run monitoring(event monitor), validated dataset script, run processing dashboard aggregator script and Olink Script here:
  cd ~/runprocessing; sh restart_all_services.sh
### Who do I talk to? ###
* Haig Djambazian <haig.djambazian@mcgill.ca>
* David Bujold <david.bujold@mcgill.ca>
* Francois Lefebvre <francois.lefebvre@mcgill.ca>

