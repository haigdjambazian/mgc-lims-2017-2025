### Procedure to update the sample manifest

1. First complete the new index definition (adapter_settings_format.txt/adapter_types.txt)  
   and/or new library type (library_protocol_list.csv) in runprocessing folder.   
2. Run "sh generate_manifest_ranges.sh <youremail>" in the runprocessing folder.
3. Unhide "ranges" tab and paste the content of the txt file emailed to you into previous manifests cell U1 (using previous version 3.0.0+ only).
4. Make sure ranges tab is hidden after updating it.
5. Update the manifest version into cell B1 of main tab (same version/date as LIMS release)  
   eg: "McGill Genome Center Sample Manifest version [3.0.0] - 2022-06-29".   
6. Make sure first tab is selected and cell B9 is selected before saving new manifest.
7. Replace the manifest in the samplesubmissiontemplates with this new manifest before continuing the release process.