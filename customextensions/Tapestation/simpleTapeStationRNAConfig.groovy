// **Sample information XPath**
// These two entries are required to locate and identify individual samples' information in the XML file. Do not edit these mappings.

baseSampleXPath = "/File[1]/Samples[1]/Sample[Observations!='Ladder']"
sampleNameXPath = "${baseSampleXPath}/Comment[1]/text()"

// **Details that correspond to the whole run**
// These are mapped to output UDFs in the LIMS, but are found in a different section of the XML file

// Commented out the unit import because it can contain the mu character and without proper validation it can cause troubles.
//process.run.UDF."Conc. Units".xPath = "/File[1]/Assay[1]/Units[1]/ConcentrationUnit[1]/text()"

// **Details that correspond to Samples**
// Example parameter that maps Sample Name values from the XML file to the corresponding process output artifact UDF named "Sample ID" in the LIMS:
// process.output.UDF."Sample ID".xPath = "${baseSampleXPath}/Name[1]/text()"

process.output.UDF."RIN".xPath = "${baseSampleXPath}/RNA[1]/RINe[1]/text()"

//Not Importing Concentration. Qubit value is the one used.
//process.output.UDF."Concentration".xPath = "${baseSampleXPath}/Concentration[1]/text()"

