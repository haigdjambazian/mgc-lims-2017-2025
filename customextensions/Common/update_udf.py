"""
    update_metadata_udf is derived from ShellScript class of the s4-clarity python package

    The class receives from a management step in clarity a csv file containing udf fields and their replacement value. After
    validating the old value, the script will replace for each listed udf the old value with the new value.

    This script is used for udf attached to samples and containers.

    The format of the csv file is the following :
    line 1 (header) : object_luid,udf_field_name,old_udf_value,new_udf_value
    line x (values) : 21-14123,concentration,10,14

    python update_metadata.py -u {username} -p {password} -l {rootURI:v2} -l {compoundOutputFileLuid1} -f {compoundOutputFileLuid0}
    Inputs :
    -u = clarity username
    -p = clarity password
    -r = API root URI
    -l = log attachment point URI on the step (optional)
    -f = input csv file LUID

    Outputs :
      A log file will be attached to the management step. 

    Author : Ulysse Fortier-Gauthier

"""

import logging
import argparse
import csv
import re
import socket

from s4.clarity.scripts import ShellScript
from s4.clarity.scripts import UserMessageException
from s4.clarity import types

log = logging.getLogger(__name__)

class update_metadata_udf(ShellScript):
    def __init__(self, options):
        """ Create instance object and modify the API URI argument due to LIMS limitations (token {baseURI} returns localhost) """
        options.lims_root_uri = "https://" + socket.gethostname() + "/api/v2"
        super(update_metadata_udf, self).__init__(options)

    def run(self, *args):
        """ Run is called by the script main(). Entry. """
        log.info("Starting script update metadata...")
        error_msg = None
        if self.authenticate_user(self.options.process_luid):        
            file_data = self.get_input_file_content(self.options.file_luid)
            if file_data:
                has_error = False
                # Execute all changes without commiting them
                self.lims.dry_run = True
                # Process updates for each element type separately
                try:
                    self.artifacts = self.lims.artifacts.batch_get_from_limsids(file_data["artifact"].keys())
                    for artifact in self.artifacts:
                        for entry in file_data["artifact"][artifact.limsid]:
                            log.info("Processing modification to artifact : " + artifact.limsid)
                            has_error = (has_error | self.process_element_modification(entry, artifact))
                except Exception as e:
                    log.error(str(e))
                    has_error = True
                try:
                    self.samples = self.lims.samples.batch_get_from_limsids(file_data["sample"].keys())
                    for sample in self.samples:
                        for entry in file_data["sample"][sample.limsid]:
                            log.info("Processing modification to sample : " + sample.limsid)
                            has_error = (has_error | self.process_element_modification(entry, sample))
                except Exception as e:
                    log.error(str(e))
                    has_error = True
                try:
                    self.processes = self.lims.processes.batch_get_from_limsids(file_data["process"].keys())
                    for process in self.processes:
                        for entry in file_data["process"][process.limsid]:
                            log.info("Processing modification to process : " + process.limsid)
                            has_error = (has_error | self.process_element_modification(entry, process))
                except Exception as e:
                    log.error(str(e))
                    has_error = True
                try:
                    self.containers = self.lims.containers.batch_get_from_limsids(file_data["container"].keys())
                    for container in self.containers:
                        for entry in file_data["container"][container.limsid]:
                            log.info("Processing modification to container : " + container.limsid)
                            has_error = (has_error | self.process_element_modification(entry, container))
                except Exception as e:
                    log.error(str(e))
                    has_error = True
                try:
                    self.projects = self.lims.projects.batch_get_from_limsids(file_data["project"].keys())
                    for project in self.projects:
                        for entry in file_data["project"][project.limsid]:
                            log.info("Processing modification to project : " + project.limsid)
                            has_error = (has_error | self.process_element_modification(entry, project))
                except Exception as e:
                    log.error(str(e))
                    has_error = True
                for entry in file_data["unknown"].keys():
                    log.error("Element with identifier '" + entry + "' is unknown. Correct and resubmit.")
                    has_error = True
                if has_error:
                    log.error("Errors found in the input file. Correct entries and try again.")
                    error_msg = "Errors were found in the update file. Consult the log for details."
                else:
                    # Commit changes to Clarity
                    log.info("Changes applied locally sending modifications to Clarity.")
                    self.lims.dry_run = False
                    self.lims.artifacts.batch_update(self.artifacts)
                    log.info("Changes to artifacts applied to Clarity.")
                    self.lims.samples.batch_update(self.samples)
                    log.info("Changes to samples applied to Clarity.")
                    for process in self.processes:
                        process.commit()
                        log.info("Change applied to clarity for process : " + process.limsid)
                    log.info("Changes to processes applied to Clarity.")
                    self.lims.containers.batch_update(self.containers)
                    log.info("Changes to containers applied to Clarity.")
                    for project in self.projects:
                        project.commit()
                        log.info("Change applied to clarity for project : " + project.limsid)
                    log.info("Changes to projects applied to Clarity.")
                    log.info("All changes applied to Clarity!")
            else:
                log.error("An update file (csv formated) need to be attached to the step (Meta data update file).")
        else:
            error_msg = "User do not have the permission to use this tool. Please see the data curator for your request."
        log.info("Metadata update complete.")
        return error_msg

    def authenticate_user(self, process_luid):
        # Get the technician field from the process launching the script.
        user = self.lims.processes.from_limsid(process_luid).technician
        isAuthorized = False
        log.info("Modifications requested by : " + user.first_name + " " + user.last_name + "(" + user.username + ").")
        for role in user.roles:
            # DataCurator is the role created for for clarity curations operations.
            if role.name == "DataCurator":
                isAuthorized = True
                log.info("User has data curation permissions. Proceeding ...")
        return isAuthorized

    def get_input_file_content(self, file_luid):
        """ Extract the new UDF data from the file attached to the curation step. 
            The content of the file is split by type of Clarity Element to edit. """
        file_content = None
        sample_luid_pattern = r"^[a-zA-Z]{3}\d+A\d+$"
        with self.lims.artifact(file_luid).file.data as f:
            file_content = {"artifact": {},
                            "sample": {},
                            "process": {},
                            "container": {},
                            "project": {},
                            "unknown": {}}
            reader = csv.DictReader(f)
            for row in reader:
                sample_match = re.search(sample_luid_pattern, row["element_luid"])
                if row["element_luid"].startswith("2-") or row["element_luid"].startswith("92-") or row["element_luid"].endswith("PA1"):
                    type_ele = "artifact"
                elif row["element_luid"].startswith("24-") or row["element_luid"].startswith("151-"):
                    type_ele = "process"
                elif row["element_luid"].startswith("27-"):
                    type_ele = "container"
                elif (row["element_luid"][:2].isalpha() and row["element_luid"][3:].isnumeric()):
                    type_ele = "project"
                elif sample_match:
                    type_ele = "sample"
                else:
                    type_ele = "unknown"
                file_content[type_ele][row["element_luid"]] = file_content[type_ele].get(row["element_luid"], list())
                file_content[type_ele][row["element_luid"]].append(row)
                log.info("Stored modification : " + row["element_luid"])
        return file_content
    
    def process_element_modification(self, entry, element):
        error = False
        current_value = str(element.get(entry["udf_field"], ""))
        if current_value:
            type_field = element.fields.get_type(entry["udf_field"])
            if type_field == types.NUMERIC:
                if entry["old_value"]:
                    converted_old_value = types.obj_to_clarity_string(types.clarity_string_to_obj(type_field, entry["old_value"]))
                else:
                    converted_old_value = entry["old_value"]
            elif type_field == types.BOOLEAN:
                converted_old_value = entry["old_value"].lower()
                current_value = current_value.lower()
            else:
                converted_old_value = entry["old_value"]
        else:
            converted_old_value = entry["old_value"]
            if entry["udf_field"] == "Name":
                current_value = element.name  # Exception to process name change requests
            elif entry["udf_field"] == "Index_Curation" and element.reagent_label_names:  # Ensure there is an existing index
                for index in element.reagent_label_names:
                    log.info("Current Index for " + element.limsid + " : " + index)
                if entry["old_value"] in element.reagent_label_names:
                    current_value = entry["old_value"]
                else:
                    current_value = element.reagent_label_names[0]  # If the requested index do not exist provide the current one
        if converted_old_value == current_value:
            log.info("limsid : '" + entry["element_luid"] + 
                    "' field : '" + entry["udf_field"] + 
                    "' value : '" + entry["old_value"] + 
                    "' can be changed to '" + entry["new_value"].strip() + "' [OK]")
            if entry["udf_field"] == "Name":
                element.name = entry["new_value"].strip()  # Exception here to change name of elements (which is not a UDF)
            elif entry["udf_field"] == "Index_Curation":
                if entry["new_value"]:
                    element.reagent_label_name = entry["new_value"].strip()  # Set reagent label (may not work for multiple labels)
                else:
                    element.remove_subnode("./reagent-label")  # Remove the reagent-label node (may not work for multiple labels)
            else:
                element[entry["udf_field"]] = entry["new_value"].strip()
        else:
            log.info("limsid : '" + entry["element_luid"] + 
                    "' field : '" + entry["udf_field"] + 
                    "' value : '" + entry["old_value"] + 
                    "' cannot be changed to '" + entry["new_value"].strip() + "' [OLD VALUE (" + converted_old_value + ") NOT EQUAL to CURRENT VALUE (" + current_value + ")]")
            error = True
        return error

    @classmethod
    def add_arguments(cls, argparser):
        super(update_metadata_udf, cls).add_arguments(argparser)
        argparser.add_argument("-f", "--fileluid", action="store",  dest="file_luid", help="File LUID for the updated data", required=True)
        argparser.add_argument("-a", "--processluid", action="store",  dest="process_luid", help="Process LUID to identify the user launching the script.", required=True)


if __name__ == "__main__":
    update_metadata_udf.main()