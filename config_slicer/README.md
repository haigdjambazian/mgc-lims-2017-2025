These xmls are the successive config slicer outputs from the Clarity lims system we used at McGill

See this link for details:
https://genologics.zendesk.com/hc/en-us/articles/213989063-Managing-Configurations-with-Config-Slicer

The xml files are first moved to the production system in /opt/gls/clarity/tools/config-slicer (xml1, xml2, etc) by IT team (files come from this git).

Then this command is then run by IT team:
java -jar config-slicer-3.0.24.jar -o importAndOverwrite -s bravoprodapp.genome.mcgill.ca -u admin -p PASSWORD -m example.txt -k example.txt.xml 

