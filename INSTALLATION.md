# Deployment Instructions to install a new Clarity instance
Note: This does not include the database copying.

## Procedure to install a full clarity stack from Genologics:
- https://genologics.zendesk.com/hc/en-us/articles/213973383-Clarity-LIMS-Installation-Procedure

## Python Packages Links:
- interop python library (http://illumina.github.io/interop/python_binding.html)
- s4-clarity python library (https://github.com/SemaphoreSolutions/s4-clarity-lib)

## Python Dependencies required:
    'certifi==2017.4.17'
    'chardet==3.0.4'
    'cycler==0.10.0'
    'et-xmlfile==1.0.1'
    'idna==2.5'
    'interop==1.1.8'
    'jdcal==1.4.1'
    'matplotlib==2.0.2'
    'numpy==1.16.4'
    'olefile==0.44'
    'openpyxl==2.6.2'
    'pandas==0.20.2'
    'Pillow==4.2.0'
    'pip==9.0.1'
    'pyBarcode==0.7'
    'pyparsing==2.2.0'
    'python-dateutil==2.6.0'
    'pytz==2017.2'
    'requests==2.18.1'
    's4-clarity==1.0.0'
    'scikit-learn==0.18.2'
    'scipy==0.19.1'
    'setuptools==33.1.1'
    'six==1.10.0'
    'sklearn==0.0'
    'urllib3==1.21.1'
    'xlrd==1.1.0'

## To obtain the list above:
    python3.5 -c 'import pip;pk=sorted(["%s==%s" % (i.key, i.version) for i in pip.get_installed_distributions()]);print(pk)' | tr -d '[]' | tr ',' '\n' | awk '{print "    "$1}'

## installation for krona
    mkdir ~/tools; cd ~/tools;
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh;
    bash Miniconda3-latest-Linux-x86_64.sh;
    ### pick /home/$USER/tools/miniconda3
    source /home/$USER/tools/miniconda3/etc/profile.d/conda.sh;
    # conda init bash;
    conda config --add channels bioconda;
    conda config --add channels conda-forge;
    conda create -n krona-env krona;
    conda activate krona-env;
    ktUpdateTaxonomy.sh;
    # test # ktImportTaxonomy -t 5 -m 3 -o test1.krona.html test1.kraken2_report;

    mkdir ~/tools/phantomjs; cd ~/tools/phantomjs;
    wget https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2;
    tar xvf phantomjs-2.1.1-linux-x86_64.tar.bz2;
    chmod 700 ./phantomjs-2.1.1-linux-x86_64/bin/phantomjs;
    rm phantomjs-2.1.1-linux-x86_64.tar.bz2;
    ### modify ./rasterise.js "page.viewportSize = { width: 450, height: 450 };" and "window.setTimeout -> 1000"
    # test # ./phantomjs-2.1.1-linux-x86_64/bin/phantomjs ./rasterise.js ../test1.krona.html ../test1.krona.png;
    
## Extra application changes not captured by config-slicer
    # Run as glsjboss
    # Define HOST=bravodevapp.genome.mcgill.ca
    cd /opt/gls/clarity/tools/permissions; java -jar permissions-tool.jar -a https://${HOST}/api/ -u admin -p <admin-password> assignPermission Researcher RemoveSampleFromWorkflow
    cd /opt/gls/clarity/tools/permissions; java -jar permissions-tool.jar -a https://${HOST}/api/ -u admin -p <admin-password> assignPermission Researcher MoveToNextStep
    cd /opt/gls/clarity/tools/permissions; java -jar permissions-tool.jar -a https://${HOST}/api/ -u admin -p <admin-password> removePermission Researcher Sample:create
    cd /opt/gls/clarity/tools/permissions; java -jar permissions-tool.jar -a https://${HOST}/api/ -u admin -p <admin-password> removePermission Researcher Sample:update
    cd /opt/gls/clarity/tools/permissions; java -jar permissions-tool.jar -a https://${HOST}/api/ -u admin -p <admin-password> assignPermission 'Facility Administrator' CanEditCompletedSteps
    cd /opt/gls/clarity/tools/permissions; java -jar permissions-tool.jar -a https://${HOST}/api/ -u admin -p <admin-password> createRole DataCurator

## MGI run processing version
    COMMIT=ddb7b96; D=/home/$LIMSUSER/mgirunprocessing-$COMMIT; rm -rf $D; mkdir $D; cd $D; git clone -b "run_processing" https://bitbucket.org/mugqic/genpipes.git; cd genpipes; git checkout $COMMIT; cd; rm -rf /home/$LIMSUSER/mgirunprocessing/genpipes; mkdir -p /home/$LIMSUSER/illumcovidanalysis; ln -s $D/genpipes /home/$LIMSUSER/mgirunprocessing/genpipes;

## Nanopore COVID run processing/secondary analysis version
    COMMIT=8279cfa; D=/home/$LIMSUSER/ontcovidrunprocessing-$COMMIT; rm -rf $D; mkdir $D; cd $D; git clone -b "master" https://bitbucket.org/mugqic/genpipes.git; cd genpipes; git checkout $COMMIT; cd; m -rf /home/$LIMSUSER/ontcovidrunprocessing/genpipes; mkdir -p /home/$LIMSUSER/illumcovidanalysis; ln -s $D/genpipes /home/$LIMSUSER/ontcovidrunprocessing/genpipes;

## Ilumina COVID secondary analysis version
    COMMIT=8279cfa; D=/home/$LIMSUSER/illumcovidanalysis-$COMMIT; rm -rf $D; mkdir $D; cd $D; git clone -b "master" https://bitbucket.org/mugqic/genpipes.git; cd genpipes; git checkout $COMMIT; cd; rm -rf /home/$LIMSUSER/illumcovidanalysis/genpipes; mkdir -p /home/$LIMSUSER/illumcovidanalysis; ln -s $D/genpipes /home/$LIMSUSER/illumcovidanalysis/genpipes;
