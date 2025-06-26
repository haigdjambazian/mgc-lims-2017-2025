# Clarity Fields and User Defined Fields (udf) for Submitted Samples #

Taken from Sample Manifest version 0.2.x

2019_10_03,	Alexander Mazur, McGill University

## Sample Submission Sheet Variables ##

| Submitted Samples UDF   | Desription                                 | Defaults                                                                                                   | Note                                                                       |
|-------------------------|--------------------------------------------|------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------|
| Sample Type             | Sample Type, see also subtype              | Tissue,Nucleic Acid,Illumina Library,Illumina Library Pool                                                 | Required, Tissue,Nucleic Acid,Illumina Library,Illumina Pool,Samples in Pool |
| Sample Name             | Sample Name, Pool Name or Existing LIMS ID | alphanumeric                                                                                               | Required, Tissue,Nucleic Acid,Illumina Library,Illumina Pool,Samples in Pool |
| Container Name          | Container Name                             | alphanumeric                                                                                               | Required, Tissue,Nucleic Acid,Illumina Library,Illumina Pool,Samples in Pool |
| Container Type          | Container Type                             | 96 well plate,Tube,384 well plate                                                                          | Required, Tissue,Nucleic Acid,Illumina Library,Illumina Pool,Samples in Pool |
| Well                    | Sample position in container               | A:3 format                                                                                                 | Required, Tissue,Nucleic Acid,Illumina Library,Illumina Pool,Samples in Pool |
| Adapter Type            | Adapter Type                               | TruSeqLT,TruSeqHT,Nextera                                                                                  | Only specify if Index Name does not exist.                                   |
| Buffer                  | Buffer                                     | Water,Ethanol                                                                                              | Optional                                                                     |
| Cohort ID               | Cohort ID                                  | alphanumeric                                                                                               | Optional                                                                     |
| Comments                | Comments                                   | alphanumeric                                                                                               | Optional                                                                     |
| Concentration           | Concentration                              | numeric                                                                                                    | Only specify if Sample Type:llumina Library,Illumina Pool                    |
| Concentration Units     | Concentration Units                        | cells/uL,ng/uL                                                                                             | Only specify if Sample Type:llumina Library,Illumina Pool                    |
| Container Barcode       | Container Barcode                          | alphanumeric                                                                                               | Optional                                                                     |
| Genome Size in Mb       | Genome Size in Mb                          | numeric                                                                                                    | Optional                                                                     |
| i5 Index                | i5 Index                                   | alphanumeric                                                                                               | Only specify if Index Name does not exist.                                   |
| i7 Index                | i7 Index                                   | alphanumeric                                                                                               | Only specify if Index Name does not exist.                                   |
| Individual ID           | Individual ID                              | alphanumeric                                                                                               | Optional                                                                     |
| Library Index Name      | Library Index Name                         | alphanumeric                                                                                               | Only specify if Sample Type:llumina Library,Sample In Pool                   |
| Library Index Series    | Library Index Series                       | alphanumeric                                                                                               | Only specify if Sample Type:llumina Library,Sample In Pool                   |
| Library Size in bases   | Library Size in bases                      | numeric                                                                                                    | Only specify if Sample Type:llumina Library,Illumina Pool                    |
| Library Type            | Library Type                               | see APPENDIX I                                                                                             | Only specify if Sample Type:llumina Library,Sample In Pool                   |
| Nucleic Acid Size in Kb | Nucleic Acid Size in Kb                    | numeric                                                                                                    | Optional                                                                     |
| Nucleic Acid Type       | Nucleic Acid Type                          | see APPENDIX I                                                                                             | Optional                                                                     |
| Number in Pool          | Number Samples in Pool                     | numeric                                                                                                    | Only specify if Sample Type:llumina Library,Illumina Pool                    |
| Reference Genome        | Reference Genome                           | see APPENDIX I                                                                                             | Optional                                                                     |
| Sample Group            | Sample Group from MaGiC study design       | alphanumeric                                                                                               | Optional                                                                     |
| Sample Type             | Sample Type                                | Tissue, Nucleic Acid, Illumina Library, Illumina Library Pool, Sample In Pool, Existing Sample or Library  | Optional                                                                     |
| Sex                     | Sex                                        | M/F                                                                                                        | Optional                                                                     |
| Species                 | Species                                    | see APPENDIX II                                                                                            | Optional                                                                     |
| Tissue Type             | Tissue Type                                | see APPENDIX I                                                                                             | Optional                                                                     |
| Tube Carrier Barcode    | Tube Carrier Barcode                       | alphanumeric                                                                                               | Tissue,Nucleic Acid,Illumina Library,Illumina Pool                           |
| Tube Carrier Name       | Tube Carrier Name                          | alphanumeric                                                                                               | Tissue,Nucleic Acid,Illumina Library,Illumina Pool                           |
| Tube Carrier Type       | Tube Carrier Type                          | 96 tubes rack,Box (10x10)                                                                                  | Tissue,Nucleic Acid,Illumina Library,Illumina Pool                           |
| Volume in uL            | Volume in uL                               | numeric                                                                                                    | Only specify if Tissue,Nucleic Acid,Illumina Library,Illumina Pool           |


## Clarity Samples UDF  ##

| Name                  | Description                                                                 | Defaults                                                                                                                                                                                                                                           | Status                                                                                             |
|-----------------------|-----------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------|
| Alias                 | Alias                                                                       | alphanumeric                                                                                                                                                                                                                                       | Optional                                                                                           |
| Application           | Applicaton Name                                                             | alphanumeric                                                                                                                                                                                                                                       | Optional                                                                                           |
| Area/Room             | Area/Room samples location                                                  | alphanumeric                                                                                                                                                                                                                                       | Optional                                                                                           |
| Barcode               | Sample Barcode                                                              | alphanumeric                                                                                                                                                                                                                                       | Optional                                                                                           |
| BASE64POOLDATA        | Information about submitted Library or Library Pool stored in base64 format | base64 format                                                                                                                                                                                                                                      | Optional, but required when Samples Type are : Illumina Library, Illumina Library Pool or Library  |
| Carrier Barcode       | Carrier barcode                                                             | alphanumeric                                                                                                                                                                                                                                       | Optional, but required when samples submitted in the carrier                                       |
| Carrier Coordinate    | Carrier coordinate                                                          | alphanumeric                                                                                                                                                                                                                                       | Optional, but required when samples submitted in the carrier                                       |
| Carrier Name          | Carrier name                                                                | alphanumeric                                                                                                                                                                                                                                       | Optional, but required when samples submitted in the carrier                                       |
| Carrier Type          | Carrier type                                                                | 96 tubes rack,Box (10x10)                                                                                                                                                                                                                          | Optional                                                                                           |
| Cohort ID             | Cohort ID                                                                   | alphanumeric                                                                                                                                                                                                                                       | Optional                                                                                           |
| Collection site       | Collection site information                                                 | alphanumeric                                                                                                                                                                                                                                       | Optional                                                                                           |
| Comments              | Sample related comments                                                     | alphanumeric                                                                                                                                                                                                                                       | Optional                                                                                           |
| Concentration         | Sample Concentration                                                        | numeric                                                                                                                                                                                                                                            | Optional                                                                                           |
| Control?              | Is sample Control?                                                          | True/False                                                                                                                                                                                                                                         | Optional                                                                                           |
| External Name         | Project Name from MaGiC                                                     | alphanumeric                                                                                                                                                                                                                                       | Optional                                                                                           |
| Floor                 | Floor sample location                                                       | alphanumeric                                                                                                                                                                                                                                       | Optional                                                                                           |
| Freezer               | Freezer sample location                                                     | alphanumeric                                                                                                                                                                                                                                       | Optional                                                                                           |
| Gender                | Geneder                                                                     | M/F, none                                                                                                                                                                                                                                          | Optional                                                                                           |
| Genome Size           | Genome szie in Mb                                                           | numeric                                                                                                                                                                                                                                            | Optional                                                                                           |
| Genome Size Units     | Genome szie Units                                                           | Mb                                                                                                                                                                                                                                                 | Optional                                                                                           |
| Individual ID         | Individual ID                                                               | alphanumeric                                                                                                                                                                                                                                       | Optional                                                                                           |
| Library Index Name    | Library Index Name                                                          | alphanumeric                                                                                                                                                                                                                                       | Optional                                                                                           |
| Library Size          | Library Size in bp                                                          | numeric                                                                                                                                                                                                                                            | Optional                                                                                           |
| Library Type          | Library Type                                                                | alphanumeric                                                                                                                                                                                                                                       | Optional                                                                                           |
| Location              | Sample location in Innovation Centre                                        | alphanumeric                                                                                                                                                                                                                                       | Optional                                                                                           |
| Nucleic Acid Size     | Nucleic Acid Size in Kb                                                     | numeric                                                                                                                                                                                                                                            | Optional                                                                                           |
| Nucleic Acid Type     | Nucleic Acid Type                                                           | Genomic DNA,cDNA,Amplicons,ChIP DNA,polyA RNA,Total RNA,Nuclear RNA,Cytoplasmic RNA,Small RNA                                                                                                                                                      | Optional                                                                                           |
| Number in Pool        | Number of Samples in Pool                                                   | numeric                                                                                                                                                                                                                                            | Optional                                                                                           |
| Organism              | Organism                                                                    | alphanumeric                                                                                                                                                                                                                                       | Optional                                                                                           |
| Pooling               | Pooling                                                                     | alphanumeric                                                                                                                                                                                                                                       | Optional                                                                                           |
| Pooling Type          | Pooling Type                                                                | alphanumeric                                                                                                                                                                                                                                       | Optional                                                                                           |
| Progress              | Progess Status                                                              | alphanumeric                                                                                                                                                                                                                                       | Optional                                                                                           |
| Read Length           | Read Length in bp                                                           | numeric                                                                                                                                                                                                                                            | Optional                                                                                           |
| Reference Genome      | Reference Genome                                                            | alphanumeric                                                                                                                                                                                                                                       | Optional                                                                                           |
| Replicate ID          | Replicate ID                                                                | alphanumeric                                                                                                                                                                                                                                       | Optional                                                                                           |
| Sample 2nd Conc       | Sample 2nd Conc                                                             | numeric                                                                                                                                                                                                                                            | Optional                                                                                           |
| Sample 2nd Conc Units | Sample 2nd Conc Units                                                       | cells/uL,ng/uL                                                                                                                                                                                                                                     | Optional                                                                                           |
| Sample Buffer         | Sample Buffer                                                               | Water,Ethanol                                                                                                                                                                                                                                      | Optional                                                                                           |
| Sample Conc Method    | Sample Conc Method                                                          | alphanumeric                                                                                                                                                                                                                                       | Optional                                                                                           |
| Sample Conc Units     | Sample Conc Units                                                           | cells/uL,ng/uL                                                                                                                                                                                                                                     | Optional                                                                                           |
| Sample Conc.          | Sample Conc.                                                                | numeric                                                                                                                                                                                                                                            | Optional                                                                                           |
| Sample Group          | Sample Group from MaGiC study design                                        | alphanumeric                                                                                                                                                                                                                                       | Optional                                                                                           |
| Sample Type           | Sample Type                                                                 | Tissue, Nucleic Acid, Illumina Library, Illumina Library Pool, Sample In Pool, Existing Sample or Library                                                                                                                                          |                                                                                                    |
| Sequencing Coverage   | Sequencing Coverage                                                         | numeric                                                                                                                                                                                                                                            | Optional                                                                                           |
| Sequencing Method     | Sequencing Method                                                           | alphanumeric                                                                                                                                                                                                                                       | Optional                                                                                           |
| Sex                   | Sex                                                                         | M/F                                                                                                                                                                                                                                                | Optional                                                                                           |
| Shelf                 | Shelf                                                                       | alphanumeric                                                                                                                                                                                                                                       | Optional                                                                                           |
| Site of Origin        | Site of Origin                                                              | alphanumeric                                                                                                                                                                                                                                       | Optional                                                                                           |
| Species               | Species                                                                     | alphanumeric                                                                                                                                                                                                                                       | Optional                                                                                           |
| Tissue Type           | Tissue Type                                                                 | Whole Blood,Buffy Coats,Serum,Solid Tissue (biopsy),Breast Tumor (frozen),Solid Tissue (biopsy),Endometrial (FFPE),Solid Tissue (biopsy) Brain,Saliva,Endometrial Lavage,Endometrial Toa Brush,Cell Culture,Crossed-Linked Cell Pellet,Cell Pellet | Optional                                                                                           |
| Tray                  | Tray                                                                        | alphanumeric                                                                                                                                                                                                                                       | Optional                                                                                           |
| Units                 | Units                                                                       | alphanumeric                                                                                                                                                                                                                                       | Optional                                                                                           |
| Volume                | Volume                                                                      | numeric                                                                                                                                                                                                                                            | Optional                                                                                           |
| Volume (uL)           | Volume (uL)                                                                 | numeric                                                                                                                                                                                                                                            | Optional                                                                                           |
| Volume Units          | Volume Units                                                                | uL                                                                                                                                                                                                                                                 | Optional                                                                                           |

## Base64 POOL DATA Header ##

| Name                   | Desription                                            | Defaults             | Status   |
|------------------------|-------------------------------------------------------|----------------------|----------|
| ProcessLUID            | Process LUID                                          | N/A                  | Optional |
| ProjectLUID            | Project LUID                                          | N/A                  | Optional |
| ProjectName            | Project Name                                          | N/A                  | Optional |
| ContainerLUID          | Container LUID                                        | N/A                  | Optional |
| ContainerName          | Container Name                                        | N/A                  | Optional |
| Position               | Position                                              | N/A                  | Optional |
| Index                  | Library Index                                         | Library Index        | Required |
| LibraryLUID            | Library LUID                                          | N/A                  | Optional |
| LibraryProcess         | Library Process Name                                  | Library Process Name | Required |
| ArtifactLUIDLibNorm    | Sample artifact LUID from Library Normalization step  | N/A                  | Optional |
| ArtifactNameLibNorm    | Sample artifact name from Library Normalization step  | N/A                  | Optional |
| SampleLUID             | Sample LUID                                           | N/A                  | Optional |
| SampleName             | Sample Name                                           | N/A                  | Required |
| Reference              | Reference genome                                      | N/A                  | Optional |
| StartDate              | Start Date                                            | N/A                  | Optional |
| SampleTag              | Sample Tag                                            | N/A                  | Optional |
| TargetCells            | Target Cells                                          | N/A                  | Optional |
| LibraryMetadataID      | Library Process LUID                                  | N/A                  | Optional |
| Species                | Species                                               | N/A                  | Optional |
| UDF/GenomeSize(Mb)     | Genome Size (Mb)                                      | N/A                  | Optional |
| Gender                 | Gender                                                | N/A, M/F             | Optional |
| PoolFraction           | Pool Fraction                                         | N/A                  | Optional |
| CaptureType            | Capture Type                                          | N/A                  | Optional |
| CaptureLUID            | Capture LUID                                          | N/A                  | Optional |
| CaptureName            | Capture Name                                          | N/A                  | Optional |
| CaptureREF_BED         | Capture REF_BED                                       | N/A                  | Optional |
| CaptureMetadataID      | Capture Process LUID                                  | N/A                  | Optional |
| ArtifactLUIDClustering | Sample artifact from Illumina Cluster Generation step | N/A                  | Optional |


| APPENDIX I                     |
|--------------------------------|
 ## Library Type ##
 PCR-free                       
 PCR-enriched                   
 WGBS                           
 RNASeq                         
 ATACSeq                        
 ChIPSeq                        
 10x Genomics Linked Reads gDNA 
 10x Genomics Single Cell RNA   
 10x Genomics Single Cell CNV   
 MCC                            
 Exome                          
 HiC                            
 ATACSeq                        
 ChIPSeq                        
 HaloPlex                       
                                
## Nucleic Acid Type ##
 Genomic DNA                    
 cDNA                           
 Amplicons                      
 ChIP DNA                       
 polyA RNA                      
 Total RNA                      
 Nuclear RNA                    
 Cytoplasmic RNA                
 Small RNA                      
                                
## Reference Genome ##
 Homo_sapiens:GRCh38            
 Homo_sapiens:GRCh37            
 Homo_sapiens:hg19              
 Mus_musculus:GRCm38            
                                
## Tissue Type ##
 Whole Blood                    
 Buffy Coats                    
 Serum                          
 Solid Tissue (biopsy)          
 Breast Tumor (frozen)          
 Solid Tissue (biopsy)          
 Endometrial (FFPE)             
 Solid Tissue (biopsy) Brain    
 Saliva                         
 Endometrial Lavage             
 Endometrial Toa Brush          
 Cell Culture                   
 Crossed-Linked Cell Pellet     
 Cell Pellet          


| APPENDIX II Species            |
|--------------------------------|

|             Species                                                      |  Species2                                     | Genome Size, Mb |
|--------------------------------------------------------------------------|-----------------------------------------------|-----------------|
| Eukaryota:Homo sapiens (Taxon ID:9606)                                   | Homo sapiens                                  | 3257.32         |
| Eukaryota:Mus musculus (Taxon ID:10090)                                  | Mus musculus                                  | 2818.97         |
| Eukaryota:Rattus norvegicus (Taxon ID:10116)                             | Rattus norvegicus                             | 2870.18         |
| Eukaryota:Drosophila melanogaster (Taxon ID:7227)                        | Drosophila melanogaster                       | 143.726         |
| Bacteria:Escherichia coli (Taxon ID:562)                                 | Escherichia coli                              | 5.5946          |
| Bacteria:Salmonella enterica (Taxon ID:594)                              | Salmonella enterica                           | 4.95138         |
| Bacteria:Staphylococcus (Taxon ID:1258)                                  | Staphylococcus                                | 5.31522         |
| Bacteria:Streptococcus pneumoniae (Taxon ID:1313)                        | Streptococcus pneumoniae                      | 2.03862         |
| Bacteria:Legionella pneumophila (Taxon ID:446)                           | Legionella pneumophila                        | 3.39775         |
| Bacteria:Klebsiella pneumoniae (Taxon ID:573)                            | Klebsiella pneumoniae                         | 5.68232         |
| Bacteria:Listeria monocytogenes (Taxon ID:1638)                          | Listeria monocytogenes                        | 2.94453         |
| Bacteria:Mycobacterium tuberculosis (Taxon ID:1719)                      | Mycobacterium tuberculosis                    | 4.50396         |
| Bacteria:Pseudomonas (Taxon ID:24)                                       | Pseudomonas                                   | 14.113          |
| Bacteria:Streptococcus (Taxon ID:659)                                    | Streptococcus                                 | 12.4349         |
| Bacteria:Clostridioides difficile (Taxon ID:1496)                        | Clostridioides difficile                      | 4.29813         |
| Bacteria:Vibrio cholerae (Taxon ID:666)                                  | Vibrio cholerae                               | 4.03346         |
| Eukaryota:Albugo candida (Taxon ID:65357)                                | Albugo candida                                | 32.9217         |
| Eukaryota:Alternaria tenuissima (Taxon ID:119927)                        | Alternaria tenuissima                         | 35.7042         |
| Eukaryota:Aphanomyces astaci (Taxon ID:112090)                           | Aphanomyces astaci                            | 75.8444         |
| Eukaryota:Arabidopsis thaliana (Taxon ID:3702)                           | Arabidopsis thaliana                          | 119.669         |
| Eukaryota:Aspergillus flavus (Taxon ID:5059)                             | Aspergillus flavus                            | 36.8923         |
| Eukaryota:Aspergillus fumigatus (Taxon ID:41122)                         | Aspergillus fumigatus                         | 29.385          |
| Eukaryota:Aspergillus niger (Taxon ID:5058)                              | Aspergillus niger                             | 34.0067         |
| Eukaryota:Aspergillus oryzae (Taxon ID:5062)                             | Aspergillus oryzae                            | 37.912          |
| Eukaryota:Babesia microti (Taxon ID:5868)                                | Babesia microti                               | 6.43448         |
| Eukaryota:Beauveria bassiana (Taxon ID:176275)                           | Beauveria bassiana                            | 33.6978         |
| Eukaryota:Beta vulgaris (Taxon ID:3555)                                  | Beta vulgaris                                 | 566.55          |
| Eukaryota:Blastocystis (Taxon ID:12967)                                  | Blastocystis                                  | 18.8172         |
| Eukaryota:Blastomyces percursus (Taxon ID:1658174)                       | Blastomyces percursus                         | 32.6653         |
| Eukaryota:Blastomyces sp. MA-2018 (Taxon ID:)                            | Blastomyces sp. MA-2018                       | 34.0485         |
| Eukaryota:Blumeria graminis (Taxon ID:34373)                             | Blumeria graminis                             | 124.489         |
| Eukaryota:Caenorhabditis (Taxon ID:6237)                                 | Caenorhabditis                                | 190.37          |
| Eukaryota:Calonectria pseudonaviculata (Taxon ID:196064)                 | Calonectria pseudonaviculata                  | 54.9752         |
| Eukaryota:Candida albicans (Taxon ID:5476)                               | Candida albicans                              | 14.2827         |
| Eukaryota:Candida auris (Taxon ID:50962)                                 | Candida auris                                 | 14.2827         |
| Eukaryota:Candida boidinii (Taxon ID:5477)                               | Candida boidinii                              | 14.2827         |
| Eukaryota:Candida glabrata (Taxon ID:5478)                               | Candida glabrata                              | 14.2827         |
| Eukaryota:Cannabis sativa (Taxon ID:3483)                                | Cannabis sativa                               | 1009.67         |
| Eukaryota:Clarireedia homoeocarpa (Taxon ID:)                            | Clarireedia homoeocarpa                       | 43.3591         |
| Eukaryota:Clavispora lusitaniae (Taxon ID:36911)                         | Clavispora lusitaniae                         | 12.1149         |
| Eukaryota:Coccidioides posadasii (Taxon ID:199306)                       | Coccidioides posadasii                        | 27.0134         |
| Eukaryota:Corynespora cassiicola (Taxon ID:59586)                        | Corynespora cassiicola                        | 44.8462         |
| Eukaryota:Cryptococcus gattii VGII (Taxon ID:294750)                     | Cryptococcus gattii VGII                      | 17.5813         |
| Eukaryota:Cryptococcus neoformans (Taxon ID:5207)                        | Cryptococcus neoformans                       | 19.0519         |
| Eukaryota:Cryptosporidium hominis (Taxon ID:237895)                      | Cryptosporidium hominis                       | 9.17973         |
| Eukaryota:Cryptosporidium parvum (Taxon ID:5807)                         | Cryptosporidium parvum                        | 9.10232         |
| Eukaryota:Cyclospora cayetanensis (Taxon ID:88456)                       | Cyclospora cayetanensis                       | 44.3636         |
| Eukaryota:Dothistroma septosporum (Taxon ID:64363)                       | Dothistroma septosporum                       | 30.2094         |
| Eukaryota:Drosophila melanogaster (Taxon ID:7227)                        | Drosophila melanogaster                       | 143.726         |
| Eukaryota:Drosophila simulans (Taxon ID:7240)                            | Drosophila simulans                           | 124.964         |
| Eukaryota:Fusarium fujikuroi (Taxon ID:5127)                             | Fusarium fujikuroi                            | 43.8323         |
| Eukaryota:Fusarium graminearum (Taxon ID:5518)                           | Fusarium graminearum                          | 36.458          |
| Eukaryota:Fusarium oxysporum (Taxon ID:5507)                             | Fusarium oxysporum                            | 61.3869         |
| Eukaryota:Fusarium proliferatum (Taxon ID:47803)                         | Fusarium proliferatum                         | 45.2103         |
| Eukaryota:Giardia intestinalis (Taxon ID:5741)                           | Giardia intestinalis                          | 11.2136         |
| Eukaryota:Heliconius cydno (Taxon ID:33424)                              | Heliconius cydno                              | 282.336         |
| Eukaryota:Heliconius elevatus (Taxon ID:33444)                           | Heliconius elevatus                           | 364.784         |
| Eukaryota:Heliconius melpomene (Taxon ID:34740)                          | Heliconius melpomene                          | 273.786         |
| Eukaryota:Heliconius pardalinus (Taxon ID:33441)                         | Heliconius pardalinus                         | 293.609         |
| Eukaryota:Heliconius timareta (Taxon ID:101932)                          | Heliconius timareta                           | 319.43          |
| Eukaryota:Homo sapiens (Taxon ID:9606)                                   | Homo sapiens                                  | 3257.32         |
| Eukaryota:Hordeum vulgare (Taxon ID:4513)                                | Hordeum vulgare                               | 4006.12         |
| Eukaryota:Hortaea werneckii (Taxon ID:91943)                             | Hortaea werneckii                             | 49.7773         |
| Eukaryota:Kluyveromyces marxianus (Taxon ID:4911)                        | Kluyveromyces marxianus                       | 10.9665         |
| Eukaryota:Komagataella pastoris (Taxon ID:4922)                          | Komagataella pastoris                         | 9.59754         |
| Eukaryota:Leishmania donovani (Taxon ID:5661)                            | Leishmania donovani                           | 32.445          |
| Eukaryota:Macaca mulatta (Taxon ID:9544)                                 | Macaca mulatta                                | 3236.22         |
| Eukaryota:Macrophomina phaseolina (Taxon ID:35725)                       | Macrophomina phaseolina                       | 48.8828         |
| Eukaryota:Malassezia furfur (Taxon ID:55194)                             | Malassezia furfur                             | 14.7622         |
| Eukaryota:Malassezia sympodialis (Taxon ID:76777)                        | Malassezia sympodialis                        | 7.66969         |
| Eukaryota:Microbotryum lychnidis-dioicae (Taxon ID:288795)               | Microbotryum lychnidis-dioicae                | 3.4705          |
| Eukaryota:Microbotryum violaceum (Taxon ID:5272)                         | Microbotryum violaceum                        | 39.9002         |
| Eukaryota:Mus musculus (Taxon ID:10090)                                  | Mus musculus                                  | 2818.97         |
| Eukaryota:Oryza rufipogon (Taxon ID:4529)                                | Oryza rufipogon                               | 339.177         |
| Eukaryota:Oryza sativa (Taxon ID:4530)                                   | Oryza sativa                                  | 374.423         |
| Eukaryota:Oryzias latipes (Taxon ID:8090)                                | Oryzias latipes                               | 734.057         |
| Eukaryota:Parastagonospora avenae (Taxon ID:1351752)                     | Parastagonospora avenae                       | 33.6779         |
| Eukaryota:Parastagonospora nodorum (Taxon ID:13684)                      | Parastagonospora nodorum                      | 37.214          |
| Eukaryota:Penicillium expansum (Taxon ID:27334)                          | Penicillium expansum                          | 32.356          |
| Eukaryota:Phytophthora capsici (Taxon ID:4784)                           | Phytophthora capsici                          | 56.0343         |
| Eukaryota:Phytophthora kernoviae (Taxon ID:325452)                       | Phytophthora kernoviae                        | 39.4812         |
| Eukaryota:Phytophthora parasitica (Taxon ID:4792)                        | Phytophthora parasitica                       | 82.3892         |
| Eukaryota:Phytophthora ramorum (Taxon ID:164328)                         | Phytophthora ramorum                          | 60.25           |
| Eukaryota:Pichia kudriavzevii (Taxon ID:4909)                            | Pichia kudriavzevii                           | 11.6791         |
| Eukaryota:Plasmodium falciparum (Taxon ID:5833)                          | Plasmodium falciparum                         | 23.3269         |
| Eukaryota:Plasmodium vivax (Taxon ID:5855)                               | Plasmodium vivax                              | 27.0137         |
| Eukaryota:Plasmodium yoelii (Taxon ID:5861)                              | Plasmodium yoelii                             | 22.7559         |
| Eukaryota:Puccinia striiformis (Taxon ID:27350)                          | Puccinia striiformis                          | 156.834         |
| Eukaryota:Puccinia triticina (Taxon ID:208348)                           | Puccinia triticina                            | 135.344         |
| Eukaryota:Pyrenophora tritici-repentis (Taxon ID:45151)                  | Pyrenophora tritici-repentis                  | 37.9975         |
| Eukaryota:Pyricularia grisea (Taxon ID:148305)                           | Pyricularia grisea                            | 44.5576         |
| Eukaryota:Pyricularia oryzae (Taxon ID:105664)                           | Pyricularia oryzae                            | 40.9791         |
| Eukaryota:Rattus norvegicus (Taxon ID:10116)                             | Rattus norvegicus                             | 2870.18         |
| Eukaryota:Rhizoctonia solani (Taxon ID:46618)                            | Rhizoctonia solani                            | 51.7059         |
| Eukaryota:Rhizophagus irregularis (Taxon ID:588596)                      | Rhizophagus irregularis                       | 136.726         |
| Eukaryota:Rhizopus microsporus (Taxon ID:4843)                           | Rhizopus microsporus                          | 25.9724         |
| Eukaryota:Rhizopus oryzae (Taxon ID:64495)                               | Rhizopus oryzae                               | 39.0638         |
| Eukaryota:Rhodotorula toruloides (Taxon ID:5286)                         | Rhodotorula toruloides                        | 20.2239         |
| Eukaryota:Saccharomyces cerevisiae (Taxon ID:4932)                       | Saccharomyces cerevisiae                      | 23.3715         |
| Eukaryota:Saccharomyces kudriavzevii (Taxon ID:114524)                   | Saccharomyces kudriavzevii                    | 23.3715         |
| Eukaryota:Saccharomyces paradoxus (Taxon ID:27291)                       | Saccharomyces paradoxus                       | 12.2147         |
| Eukaryota:Saccharomyces pastorianus (Taxon ID:27292)                     | Saccharomyces pastorianus                     | 22.5009         |
| Eukaryota:Saccharomyces sp. 'boulardii' (Taxon ID:252598)                | Saccharomyces sp. 'boulardii'                 | 12.0011         |
| Eukaryota:Solanum verrucosum (Taxon ID:315347)                           | Solanum verrucosum                            | 730.142         |
| Eukaryota:Sus scrofa (Taxon ID:9823)                                     | Sus scrofa                                    | 2501.91         |
| Eukaryota:Tolypocladium inflatum (Taxon ID:29910)                        | Tolypocladium inflatum                        | 31.7178         |
| Eukaryota:Toxoplasma gondii (Taxon ID:5811)                              | Toxoplasma gondii                             | 65.6681         |
| Eukaryota:Trichophyton rubrum (Taxon ID:5551)                            | Trichophyton rubrum                           | 22.53           |
| Eukaryota:Triticum aestivum (Taxon ID:4565)                              | Triticum aestivum                             | 14547.3         |
| Eukaryota:Triticum dicoccoides (Taxon ID:85692)                          | Triticum dicoccoides                          | 10677.9         |
| Eukaryota:Trypanosoma cruzi (Taxon ID:5693)                              | Trypanosoma cruzi                             | 89.9375         |
| Eukaryota:Venturia inaequalis (Taxon ID:5025)                            | Venturia inaequalis                           | 72.7916         |
| Eukaryota:Verticillium dahliae (Taxon ID:27337)                          | Verticillium dahliae                          | 33.9003         |
| Eukaryota:Yarrowia lipolytica (Taxon ID:4952)                            | Yarrowia lipolytica                           | 20.5509         |
| Eukaryota:Zea mays (Taxon ID:4577)                                       | Zea mays                                      | 2135.08         |
| Eukaryota:Zymoseptoria tritici (Taxon ID:336722)                         | Zymoseptoria tritici                          | 39.6863         |
| Bacteria:Acidimicrobiaceae bacterium (Taxon ID:410722)                   | Acidimicrobiaceae bacterium                   | 6.92735         |
| Bacteria:Acidobacteria bacterium (Taxon ID:171953)                       | Acidobacteria bacterium                       | 9.13755         |
| Bacteria:Acidobacteriaceae bacterium (Taxon ID:194705)                   | Acidobacteriaceae bacterium                   | 8.04529         |
| Bacteria:Acinetobacter (Taxon ID:468)                                    | Acinetobacter                                 | 6.06972         |
| Bacteria:Acinetobacter baumannii (Taxon ID:470)                          | Acinetobacter baumannii                       | 4.33579         |
| Bacteria:Acinetobacter pittii (Taxon ID:48296)                           | Acinetobacter pittii                          | 3.86253         |
| Bacteria:Bacillus anthracis (Taxon ID:1392)                              | Bacillus anthracis                            | 5.22866         |
| Bacteria:Bacillus (Taxon ID:235)                                         | Bacillus                                      | 8.48059         |
| Bacteria:Bacillus cereus (Taxon ID:1392)                                 | Bacillus cereus                               | 5.42708         |
| Bacteria:Bacillus subtilis (Taxon ID:1423)                               | Bacillus subtilis                             | 4.21561         |
| Bacteria:Bacillus thuringiensis (Taxon ID:1428)                          | Bacillus thuringiensis                        | 6.67292         |
| Bacteria:Bacillus toyonensis (Taxon ID:155322)                           | Bacillus toyonensis                           | 6.59632         |
| Bacteria:bacterium (Taxon ID:20)                                         | bacterium                                     | 35.5792         |
| Bacteria:Bacteroidales bacterium (Taxon ID:194843)                       | Bacteroidales bacterium                       | 5.9612          |
| Bacteria:Bacteroides (Taxon ID:539)                                      | Bacteroides                                   | 8.49584         |
| Bacteria:Bacteroidetes bacterium (Taxon ID:152509)                       | Bacteroidetes bacterium                       | 6.56804         |
| Bacteria:Bifidobacterium longum (Taxon ID:1679)                          | Bifidobacterium longum                        | 2.26027         |
| Bacteria:Bordetella pertussis (Taxon ID:520)                             | Bordetella pertussis                          | 4.08619         |
| Bacteria:Brucella abortus (Taxon ID:235)                                 | Brucella abortus                              | 3.82341         |
| Bacteria:Brucella melitensis (Taxon ID:235)                              | Brucella melitensis                           | 3.29493         |
| Bacteria:Burkholderia (Taxon ID:292)                                     | Burkholderia                                  | 11.4611         |
| Bacteria:Burkholderia cenocepacia (Taxon ID:95486)                       | Burkholderia cenocepacia                      | 8.97605         |
| Bacteria:Burkholderia multivorans (Taxon ID:87883)                       | Burkholderia multivorans                      | 7.79642         |
| Bacteria:Burkholderia pseudomallei (Taxon ID:28450)                      | Burkholderia pseudomallei                     | 7.24755         |
| Bacteria:Burkholderia ubonensis (Taxon ID:101571)                        | Burkholderia ubonensis                        | 7.18907         |
| Bacteria:Campylobacter coli (Taxon ID:195)                               | Campylobacter coli                            | 2.03392         |
| Bacteria:Campylobacter jejuni (Taxon ID:197)                             | Campylobacter jejuni                          | 1.84722         |
| Bacteria:Chloroflexi bacterium (Taxon ID:166587)                         | Chloroflexi bacterium                         | 9.36641         |
| Bacteria:Clostridiales bacterium (Taxon ID:172733)                       | Clostridiales bacterium                       | 7.41606         |
| Bacteria:Clostridioides difficile (Taxon ID:1496)                        | Clostridioides difficile                      | 4.29813         |
| Bacteria:Clostridium (Taxon ID:974)                                      | Clostridium                                   | 8.7629          |
| Bacteria:Clostridium botulinum (Taxon ID:1491)                           | Clostridium botulinum                         | 3.20759         |
| Bacteria:Collinsella (Taxon ID:74426)                                    | Collinsella                                   | 2.83645         |
| Bacteria:Corynebacterium diphtheriae (Taxon ID:1717)                     | Corynebacterium diphtheriae                   | 2.46367         |
| Bacteria:Cronobacter sakazakii (Taxon ID:28141)                          | Cronobacter sakazakii                         | 4.66357         |
| Bacteria:Cutibacterium acnes (Taxon ID:1747)                             | Cutibacterium acnes                           | 2.56026         |
| Bacteria:Deltaproteobacteria bacterium (Taxon ID:34034)                  | Deltaproteobacteria bacterium                 | 10.7529         |
| Bacteria:Enterobacter cloacae (Taxon ID:550)                             | Enterobacter cloacae                          | 5.88078         |
| Bacteria:Enterobacter hormaechei (Taxon ID:550)                          | Enterobacter hormaechei                       | 5.67934         |
| Bacteria:Enterococcus faecalis (Taxon ID:1351)                           | Enterococcus faecalis                         | 2.93304         |
| Bacteria:Enterococcus faecium (Taxon ID:1352)                            | Enterococcus faecium                          | 3.05257         |
| Bacteria:Escherichia coli (Taxon ID:562)                                 | Escherichia coli                              | 5.5946          |
| Bacteria:Francisella tularensis (Taxon ID:263)                           | Francisella tularensis                        | 2.04703         |
| Bacteria:Gammaproteobacteria bacterium (Taxon ID:86473)                  | Gammaproteobacteria bacterium                 | 9.36023         |
| Bacteria:Haemophilus influenzae (Taxon ID:725)                           | Haemophilus influenzae                        | 1.83014         |
| Bacteria:Helicobacter pylori (Taxon ID:210)                              | Helicobacter pylori                           | 1.66787         |
| Bacteria:Klebsiella aerogenes (Taxon ID:548)                             | Klebsiella aerogenes                          | 5.28035         |
| Bacteria:Klebsiella pneumoniae (Taxon ID:573)                            | Klebsiella pneumoniae                         | 5.68232         |
| Bacteria:Klebsiella quasipneumoniae (Taxon ID:1328376)                   | Klebsiella quasipneumoniae                    | 6.80202         |
| Bacteria:Klebsiella variicola (Taxon ID:244366)                          | Klebsiella variicola                          | 9.5794          |
| Bacteria:Lactobacillus plantarum (Taxon ID:1590)                         | Lactobacillus plantarum                       | 3.34862         |
| Bacteria:Lactococcus lactis (Taxon ID:1358)                              | Lactococcus lactis                            | 2.36559         |
| Bacteria:Legionella pneumophila (Taxon ID:446)                           | Legionella pneumophila                        | 3.39775         |
| Bacteria:Leptospira interrogans (Taxon ID:173)                           | Leptospira interrogans                        | 4.69813         |
| Bacteria:Listeria monocytogenes (Taxon ID:1638)                          | Listeria monocytogenes                        | 2.94453         |
| Bacteria:Mesorhizobium (Taxon ID:381)                                    | Mesorhizobium                                 | 13.4735         |
| Bacteria:Microbacterium (Taxon ID:1428)                                  | Microbacterium                                | 7.01076         |
| Bacteria:Mycobacterium avium (Taxon ID:1764)                             | Mycobacterium avium                           | 4.58367         |
| Bacteria:Mycobacterium (Taxon ID:727)                                    | Mycobacterium                                 | 10.0614         |
| Bacteria:Mycobacterium tuberculosis (Taxon ID:1719)                      | Mycobacterium tuberculosis                    | 4.50396         |
| Bacteria:Mycobacteroides abscessus (Taxon ID:)                           | Mycobacteroides abscessus                     | 9.97688         |
| Bacteria:Neisseria gonorrhoeae (Taxon ID:485)                            | Neisseria gonorrhoeae                         | 2.15392         |
| Bacteria:Neisseria meningitidis (Taxon ID:487)                           | Neisseria meningitidis                        | 2.27236         |
| Bacteria:Oenococcus oeni (Taxon ID:1247)                                 | Oenococcus oeni                               | 1.78052         |
| Bacteria:Pasteurella multocida (Taxon ID:747)                            | Pasteurella multocida                         | 2.27184         |
| Bacteria:Prevotella (Taxon ID:838)                                       | Prevotella                                    | 5.97551         |
| Bacteria:Prochlorococcus (Taxon ID:1218)                                 | Prochlorococcus                               | 2.79008         |
| Bacteria:Pseudomonas aeruginosa (Taxon ID:287)                           | Pseudomonas aeruginosa                        | 6.2644          |
| Bacteria:Pseudomonas (Taxon ID:24)                                       | Pseudomonas                                   | 14.113          |
| Bacteria:Pseudomonas stutzeri (Taxon ID:316)                             | Pseudomonas stutzeri                          | 4.54793         |
| Bacteria:Pseudomonas syringae (Taxon ID:317)                             | Pseudomonas syringae                          | 6.53826         |
| Bacteria:Rhizobiales bacterium (Taxon ID:189966)                         | Rhizobiales bacterium                         | 10.2866         |
| Bacteria:Rhizobium leguminosarum (Taxon ID:384)                          | Rhizobium leguminosarum                       | 6.51806         |
| Bacteria:Ruminococcus (Taxon ID:1263)                                    | Ruminococcus                                  | 7.8496          |
| Bacteria:Salmonella enterica (Taxon ID:594)                              | Salmonella enterica                           | 4.95138         |
| Bacteria:Serratia marcescens (Taxon ID:615)                              | Serratia marcescens                           | 5.1138          |
| Bacteria:Shigella flexneri (Taxon ID:623)                                | Shigella flexneri                             | 4.82882         |
| Bacteria:Shigella sonnei (Taxon ID:624)                                  | Shigella sonnei                               | 5.63259         |
| Bacteria:Sinorhizobium meliloti (Taxon ID:382)                           | Sinorhizobium meliloti                        | 6.69169         |
| Bacteria:Staphylococcus aureus (Taxon ID:1280)                           | Staphylococcus aureus                         | 2.82136         |
| Bacteria:Staphylococcus (Taxon ID:1258)                                  | Staphylococcus                                | 5.31522         |
| Bacteria:Staphylococcus epidermidis (Taxon ID:1282)                      | Staphylococcus epidermidis                    | 2.56461         |
| Bacteria:Staphylococcus haemolyticus (Taxon ID:1283)                     | Staphylococcus haemolyticus                   | 2.69786         |
| Bacteria:Staphylococcus pseudintermedius (Taxon ID:283734)               | Staphylococcus pseudintermedius               | 2.61738         |
| Bacteria:Stenotrophomonas maltophilia (Taxon ID:40324)                   | Stenotrophomonas maltophilia                  | 4.85113         |
| Bacteria:Streptococcus agalactiae (Taxon ID:1311)                        | Streptococcus agalactiae                      | 2.16027         |
| Bacteria:Streptococcus (Taxon ID:659)                                    | Streptococcus                                 | 12.4349         |
| Bacteria:Streptococcus equi (Taxon ID:1335)                              | Streptococcus equi                            | 2.14987         |
| Bacteria:Streptococcus mutans (Taxon ID:1309)                            | Streptococcus mutans                          | 2.03293         |
| Bacteria:Streptococcus pneumoniae (Taxon ID:1313)                        | Streptococcus pneumoniae                      | 2.03862         |
| Bacteria:Streptococcus pyogenes (Taxon ID:1314)                          | Streptococcus pyogenes                        | 1.85243         |
| Bacteria:Streptococcus suis (Taxon ID:1307)                              | Streptococcus suis                            | 2.17081         |
| Bacteria:Streptomyces (Taxon ID:1836)                                    | Streptomyces                                  | 15.0929         |
| Bacteria:uncultured Clostridiales bacterium (Taxon ID:172733)            | uncultured Clostridiales bacterium            | 4.6733          |
| Bacteria:Verrucomicrobia bacterium (Taxon ID:156588)                     | Verrucomicrobia bacterium                     | 8.5014          |
| Bacteria:Vibrio cholerae (Taxon ID:666)                                  | Vibrio cholerae                               | 4.03346         |
| Bacteria:Vibrio parahaemolyticus (Taxon ID:670)                          | Vibrio parahaemolyticus                       | 5.16577         |
| Bacteria:Xanthomonas oryzae (Taxon ID:347)                               | Xanthomonas oryzae                            | 5.23855         |
| Bacteria:Yersinia enterocolitica (Taxon ID:630)                          | Yersinia enterocolitica                       | 4.68362         |
| Bacteria:Yersinia pestis (Taxon ID:632)                                  | Yersinia pestis                               | 4.82986         |
| Viruses:Acanthamoeba polyphaga mimivirus (Taxon ID:212035)               | Acanthamoeba polyphaga mimivirus              | 1.25866         |
| Viruses:African horse sickness virus (Taxon ID:10897)                    | African horse sickness virus                  | 0.019543        |
| Viruses:African swine fever virus (Taxon ID:10497)                       | African swine fever virus                     | 0.193886        |
| Viruses:Ageratum yellow vein virus (Taxon ID:44560)                      | Ageratum yellow vein virus                    | 0.002768        |
| Viruses:Alphapapillomavirus 3 (Taxon ID:333767)                          | Alphapapillomavirus 3                         | 0.008104        |
| Viruses:Avian orthoreovirus (Taxon ID:38170)                             | Avian orthoreovirus                           | 0.023593        |
| Viruses:Banana bunchy top virus (Taxon ID:12585)                         | Banana bunchy top virus                       | 0.006407        |
| Viruses:Bat circovirus (Taxon ID:1072162)                                | Bat circovirus                                | 0.002979        |
| Viruses:Beak and feather disease virus (Taxon ID:77856)                  | Beak and feather disease virus                | 0.002051        |
| Viruses:Betapapillomavirus 1 (Taxon ID:337051)                           | Betapapillomavirus 1                          | 0.007779        |
| Viruses:Betapapillomavirus 2 (Taxon ID:333924)                           | Betapapillomavirus 2                          | 0.007562        |
| Viruses:Bluetongue virus (Taxon ID:10900)                                | Bluetongue virus                              | 0.019202        |
| Viruses:Brucella virus Tb (Taxon ID:1984800)                             | Brucella virus Tb                             | 0.041143        |
| Viruses:Canine circovirus (Taxon ID:1194757)                             | Canine circovirus                             | 0.002064        |
| Viruses:Circovirus (Taxon ID:39725)                                      | Circovirus                                    | 0.003124        |
| Viruses:Classical swine fever virus (Taxon ID:11096)                     | Classical swine fever virus                   | 0.012296        |
| Viruses:Columbid circovirus (Taxon ID:126070)                            | Columbid circovirus                           | 0.002043        |
| Viruses:Cowpox virus (Taxon ID:10243)                                    | Cowpox virus                                  | 0.229131        |
| Viruses:CRESS viruses (Taxon ID:)                                        | CRESS viruses                                 | 0.006979        |
| Viruses:Cucumber mosaic virus (Taxon ID:12305)                           | Cucumber mosaic virus                         | 0.009195        |
| Viruses:Cyanophage S-RIM12 (Taxon ID:1278402)                            | Cyanophage S-RIM12                            | 0.176285        |
| Viruses:Duck circovirus (Taxon ID:324685)                                | Duck circovirus                               | 0.001996        |
| Viruses:Eel River basin pequenovirus (Taxon ID:1609634)                  | Eel River basin pequenovirus                  | 0.006438        |
| Viruses:Enterobacteria phage f1 (Taxon ID:10863)                         | Enterobacteria phage f1                       | 0.006407        |
| Viruses:Enterobacteria phage phiX174 sensu lato (Taxon ID:374840)        | Enterobacteria phage phiX174 sensu lato       | 0.005387        |
| Viruses:Enterovirus C (Taxon ID:42769)                                   | Enterovirus C                                 | 0.00744         |
| Viruses:Escherichia virus G4 (Taxon ID:1986034)                          | Escherichia virus G4                          | 0.005577        |
| Viruses:Escherichia virus phiX174 (Taxon ID:10847)                       | Escherichia virus phiX174                     | 0.005388        |
| Viruses:Gammapapillomavirus 19 (Taxon ID:1513264)                        | Gammapapillomavirus 19                        | 0.007289        |
| Viruses:Gammapapillomavirus 22 (Taxon ID:1961679)                        | Gammapapillomavirus 22                        | 0.007309        |
| Viruses:Gammapapillomavirus 24 (Taxon ID:1961681)                        | Gammapapillomavirus 24                        | 0.007326        |
| Viruses:Gammapapillomavirus 7 (Taxon ID:1175849)                         | Gammapapillomavirus 7                         | 0.007417        |
| Viruses:Gammapapillomavirus (Taxon ID:325455)                            | Gammapapillomavirus                           | 0.007417        |
| Viruses:Giant panda associated gemycircularvirus (Taxon ID:2016461)      | Giant panda associated gemycircularvirus      | 0.00224         |
| Viruses:Gokushovirus WZ-2015a (Taxon ID:1758150)                         | Gokushovirus WZ-2015a                         | 0.006028        |
| Viruses:Goose circovirus (Taxon ID:146032)                               | Goose circovirus                              | 0.001822        |
| Viruses:Guaroa orthobunyavirus (Taxon ID:1933274)                        | Guaroa orthobunyavirus                        | 0.012265        |
| Viruses:Hepacivirus C (Taxon ID:11103)                                   | Hepacivirus C                                 | 0.009443        |
| Viruses:Hepatitis B virus (Taxon ID:10407)                               | Hepatitis B virus                             | 0.003248        |
| Viruses:Honeysuckle yellow vein virus (Taxon ID:240865)                  | Honeysuckle yellow vein virus                 | 0.002784        |
| Viruses:Human alphaherpesvirus 1 (Taxon ID:10298)                        | Human alphaherpesvirus 1                      | 0.152261        |
| Viruses:Human alphaherpesvirus 2 (Taxon ID:10310)                        | Human alphaherpesvirus 2                      | 0.155503        |
| Viruses:Human gammaherpesvirus 4 (Taxon ID:10376)                        | Human gammaherpesvirus 4                      | 0.172764        |
| Viruses:Human gut gokushovirus (Taxon ID:1986031)                        | Human gut gokushovirus                        | 0.006042        |
| Viruses:Human immunodeficiency virus 1 (Taxon ID:11676)                  | Human immunodeficiency virus 1                | 0.009181        |
| Viruses:Human immunodeficiency virus 2 (Taxon ID:11709)                  | Human immunodeficiency virus 2                | 0.011443        |
| Viruses:Human orthopneumovirus (Taxon ID:11250)                          | Human orthopneumovirus                        | 0.015281        |
| Viruses:Human smacovirus 1 (Taxon ID:1595998)                            | Human smacovirus 1                            | 0.002477        |
| Viruses:Influenza A virus (Taxon ID:11320)                               | Influenza A virus                             | 0.013158        |
| Viruses:Lactococcus phage 936 sensu lato (Taxon ID:354259)               | Lactococcus phage 936 sensu lato              | 0.033178        |
| Viruses:Maize streak virus (Taxon ID:10821)                              | Maize streak virus                            | 0.002701        |
| Viruses:Mammalian 2 orthobornavirus (Taxon ID:)                          | Mammalian 2 orthobornavirus                   | 0.008798        |
| Viruses:Muscovy duck circovirus (Taxon ID:257468)                        | Muscovy duck circovirus                       | 0.001995        |
| Viruses:Mycobacterium virus Bxz1 (Taxon ID:2006134)                      | Mycobacterium virus Bxz1                      | 0.157204        |
| Viruses:Mycobacterium virus Peaches (Taxon ID:663557)                    | Mycobacterium virus Peaches                   | 0.051377        |
| Viruses:Mycobacterium virus Pg1 (Taxon ID:1986538)                       | Mycobacterium virus Pg1                       | 0.069           |
| Viruses:Mycobacterium virus Soto (Taxon ID:1982928)                      | Mycobacterium virus Soto                      | 0.069037        |
| Viruses:Myxoma virus (Taxon ID:10273)                                    | Myxoma virus                                  | 0.162519        |
| Viruses:Nipah henipavirus (Taxon ID:121791)                              | Nipah henipavirus                             | 0.018252        |
| Viruses:Papaya leaf curl virus (Taxon ID:53260)                          | Papaya leaf curl virus                        | 0.002769        |
| Viruses:Pigeon circovirus (Taxon ID:1414603)                             | Pigeon circovirus                             | 0.002041        |
| Viruses:Porcine circovirus 1 (Taxon ID:133704)                           | Porcine circovirus 1                          | 0.00176         |
| Viruses:Porcine circovirus 2 (Taxon ID:85708)                            | Porcine circovirus 2                          | 0.001778        |
| Viruses:Porcine circovirus 3 (Taxon ID:1868221)                          | Porcine circovirus 3                          | 0.002006        |
| Viruses:Porcine circovirus-like virus P1 (Taxon ID:1506546)              | Porcine circovirus-like virus P1              | 0.000648        |
| Viruses:Porcine epidemic diarrhea virus (Taxon ID:28295)                 | Porcine epidemic diarrhea virus               | 0.028061        |
| Viruses:Pseudomonas virus PB1 (Taxon ID:2006179)                         | Pseudomonas virus PB1                         | 0.06645         |
| Viruses:Rabies lyssavirus (Taxon ID:11292)                               | Rabies lyssavirus                             | 0.011932        |
| Viruses:Rodent stool-associated circular genome virus (Taxon ID:1074214) | Rodent stool-associated circular genome virus | 0.003781        |
| Viruses:Rotavirus A (Taxon ID:28875)                                     | Rotavirus A                                   | 0.020421        |
| Viruses:Rotavirus C (Taxon ID:36427)                                     | Rotavirus C                                   | 0.018505        |
| Viruses:Severe fever with thrombocytopenia virus (Taxon ID:1003835)      | Severe fever with thrombocytopenia virus      | 0.011492        |
| Viruses:SFTS phlebovirus (Taxon ID:1933190)                              | SFTS phlebovirus                              | 0.011517        |
| Viruses:Simian immunodeficiency virus (Taxon ID:11711)                   | Simian immunodeficiency virus                 | 0.009623        |
| Viruses:Staphylococcus virus G1 (Taxon ID:292029)                        | Staphylococcus virus G1                       | 0.148564        |
| Viruses:Sulfolobus spindle-shaped virus (Taxon ID:244589)                | Sulfolobus spindle-shaped virus               | 0.018548        |
| Viruses:Sweet potato leaf curl virus (Taxon ID:100755)                   | Sweet potato leaf curl virus                  | 0.002844        |
| Viruses:Synechococcus phage ACG-2014a (Taxon ID:1493507)                 | Synechococcus phage ACG-2014a                 | 0.172372        |
| Viruses:Synechococcus phage ACG-2014b (Taxon ID:1493508)                 | Synechococcus phage ACG-2014b                 | 0.172874        |
| Viruses:Synechococcus phage ACG-2014d (Taxon ID:1493509)                 | Synechococcus phage ACG-2014d                 | 0.179323        |
| Viruses:Synechococcus phage ACG-2014f (Taxon ID:1493511)                 | Synechococcus phage ACG-2014f                 | 0.228143        |
| Viruses:Synechococcus phage S-RIM2 (Taxon ID:687800)                     | Synechococcus phage S-RIM2                    | 0.175777        |
| Viruses:unclassified Anelloviridae (Taxon ID:363628)                     | unclassified Anelloviridae                    | 0.003965        |
| Viruses:unclassified bacterial viruses (Taxon ID:12333)                  | unclassified bacterial viruses                | 0.04052         |
| Viruses:unclassified Circoviridae (Taxon ID:642248)                      | unclassified Circoviridae                     | 0.004423        |
| Viruses:unclassified Inoviridae (Taxon ID:456491)                        | unclassified Inoviridae                       | 0.008707        |
| Viruses:unclassified Microviridae (Taxon ID:117574)                      | unclassified Microviridae                     | 0.008312        |
| Viruses:unclassified Myoviridae (Taxon ID:196896)                        | unclassified Myoviridae                       | 0.419387        |
| Viruses:unclassified Siphoviridae (Taxon ID:196894)                      | unclassified Siphoviridae                     | 0.115924        |
| Viruses:unclassified viruses (Taxon ID:12429)                            | unclassified viruses                          | 0.668031        |
| Viruses:uncultured Caudovirales phage (Taxon ID:)                        | uncultured Caudovirales phage                 | 0.14151         |
| Viruses:uncultured marine virus (Taxon ID:186617)                        | uncultured marine virus                       | 49.3129         |
| Viruses:uncultured Mediterranean phage uvMED (Taxon ID:1407671)          | uncultured Mediterranean phage uvMED          | 0.044705        |
| Viruses:uncultured Mediterranean phage (Taxon ID:1262072)                | uncultured Mediterranean phage                | 0.044705        |
| Viruses:uncultured virus (Taxon ID:340016)                               | uncultured virus                              | 0.078637        |
| Viruses:unidentified circular ssDNA virus (Taxon ID:1862826)             | unidentified circular ssDNA virus             | 0.003665        |
| Viruses:unidentified phage (Taxon ID:38018)                              | unidentified phage                            | 0.058916        |
| Viruses:unidentified virus (Taxon ID:1214906)                            | unidentified virus                            | 0.001409        |
| Viruses:Vibrio phage ICP1 (Taxon ID:979525)                              | Vibrio phage ICP1                             | 0.129373        |
| Viruses:White spot syndrome virus (Taxon ID:92652)                       | White spot syndrome virus                     | 0.309286        |
| Archaea:Acidilobus (Taxon ID:105850)                                     | Acidilobus                                    | 1.54851         |
| Archaea:Aciduliprofundum (Taxon ID:379546)                               | Aciduliprofundum                              | 1.48678         |
| Archaea:ANME-2 cluster archaeon (Taxon ID:1869250)                       | ANME-2 cluster archaeon                       | 3.60934         |
| Archaea:Archaeoglobaceae archaeon (Taxon ID:1507183)                     | Archaeoglobaceae archaeon                     | 2.35857         |
| Archaea:Archaeoglobales archaeon (Taxon ID:309173)                       | Archaeoglobales archaeon                      | 3.40804         |
| Archaea:Archaeoglobi archaeon (Taxon ID:763499)                          | Archaeoglobi archaeon                         | 2.14862         |
| Archaea:Archaeoglobus (Taxon ID:2233)                                    | Archaeoglobus                                 | 2.70174         |
| Archaea:Archaeoglobus fulgidus (Taxon ID:2234)                           | Archaeoglobus fulgidus                        | 2.1784          |
| Archaea:archaeon (Taxon ID:13776)                                        | archaeon                                      | 13.3999         |
| Archaea:Caldisphaera (Taxon ID:200414)                                   | Caldisphaera                                  | 1.54685         |
| Archaea:Caldivirga (Taxon ID:76886)                                      | Caldivirga                                    | 2.26047         |
| Archaea:Candidatus Aenigmarchaeota archaeon (Taxon ID:1046938)           | Candidatus Aenigmarchaeota archaeon           | 1.41047         |
| Archaea:Candidatus Altiarchaeales archaeon (Taxon ID:1849261)            | Candidatus Altiarchaeales archaeon            | 3.18802         |
| Archaea:Candidatus Altiarchaeum (Taxon ID:1803512)                       | Candidatus Altiarchaeum                       | 1.66097         |
| Archaea:Candidatus Bathyarchaeota archaeon (Taxon ID:1700835)            | Candidatus Bathyarchaeota archaeon            | 3.5061          |
| Archaea:Candidatus Diapherotrites archaeon (Taxon ID:1852841)            | Candidatus Diapherotrites archaeon            | 1.1309          |
| Archaea:Candidatus Geothermarchaeota archaeon (Taxon ID:1935120)         | Candidatus Geothermarchaeota archaeon         | 1.67187         |
| Archaea:Candidatus Heimdallarchaeota archaeon (Taxon ID:1841596)         | Candidatus Heimdallarchaeota archaeon         | 5.68404         |
| Archaea:Candidatus Korarchaeota archaeon (Taxon ID:1868214)              | Candidatus Korarchaeota archaeon              | 2.24355         |
| Archaea:Candidatus Lokiarchaeota archaeon (Taxon ID:1849166)             | Candidatus Lokiarchaeota archaeon             | 4.33417         |
| Archaea:Candidatus Methanomethylophilus (Taxon ID:1236689)               | Candidatus Methanomethylophilus               | 1.72311         |
| Archaea:Candidatus Methanoperedens (Taxon ID:1392997)                    | Candidatus Methanoperedens                    | 3.73847         |
| Archaea:Candidatus Nanobsidianus stetteri (Taxon ID:1294122)             | Candidatus Nanobsidianus stetteri             | 0.593789        |
| Archaea:Candidatus Nanohaloarchaeota archaeon (Taxon ID:)                | Candidatus Nanohaloarchaeota archaeon         | 1.20142         |
| Archaea:Candidatus Nitrosopelagicus (Taxon ID:1410606)                   | Candidatus Nitrosopelagicus                   | 1.50782         |
| Archaea:Candidatus Pacearchaeota archaeon (Taxon ID:1801880)             | Candidatus Pacearchaeota archaeon             | 6.60495         |
| Archaea:Candidatus Parvarchaeota archaeon (Taxon ID:1916008)             | Candidatus Parvarchaeota archaeon             | 0.842113        |
| Archaea:Candidatus Thorarchaeota archaeon (Taxon ID:1706443)             | Candidatus Thorarchaeota archaeon             | 4.38906         |
| Archaea:Candidatus Verstraetearchaeota archaeon (Taxon ID:1916019)       | Candidatus Verstraetearchaeota archaeon       | 1.93766         |
| Archaea:Candidatus Woesearchaeota archaeon (Taxon ID:1802470)            | Candidatus Woesearchaeota archaeon            | 2.94457         |
| Archaea:Crenarchaeota archaeon (Taxon ID:29281)                          | Crenarchaeota archaeon                        | 3.31156         |
| Archaea:Desulfurococcus amylolyticus (Taxon ID:94694)                    | Desulfurococcus amylolyticus                  | 1.36522         |
| Archaea:Euryarchaeota archaeon (Taxon ID:913322)                         | Euryarchaeota archaeon                        | 7.41692         |
| Archaea:Fervidicoccus fontis (Taxon ID:683846)                           | Fervidicoccus fontis                          | 1.34411         |
| Archaea:Hadesarchaea archaeon (Taxon ID:1775754)                         | Hadesarchaea archaeon                         | 1.24144         |
| Archaea:Haladaptatus paucihalophilus (Taxon ID:367189)                   | Haladaptatus paucihalophilus                  | 4.31754         |
| Archaea:Halalkalicoccus jeotgali (Taxon ID:413810)                       | Halalkalicoccus jeotgali                      | 3.69865         |
| Archaea:Haloarcula (Taxon ID:2237)                                       | Haloarcula                                    | 4.54443         |
| Archaea:Haloarcula hispanica (Taxon ID:51589)                            | Haloarcula hispanica                          | 3.89            |
| Archaea:Halobacterium hubeiense (Taxon ID:1407499)                       | Halobacterium hubeiense                       | 3.13035         |
| Archaea:Halobellus (Taxon ID:660517)                                     | Halobellus                                    | 3.87139         |
| Archaea:Haloferax (Taxon ID:2246)                                        | Haloferax                                     | 4.36621         |
| Archaea:Haloferax mediterranei (Taxon ID:2252)                           | Haloferax mediterranei                        | 3.90471         |
| Archaea:Halogeometricum borinquense (Taxon ID:60847)                     | Halogeometricum borinquense                   | 3.94447         |
| Archaea:Halonotius (Taxon ID:268735)                                     | Halonotius                                    | 3.00969         |
| Archaea:Haloquadratum walsbyi (Taxon ID:293091)                          | Haloquadratum walsbyi                         | 3.26048         |
| Archaea:Halorubraceae archaeon (Taxon ID:)                               | Halorubraceae archaeon                        | 3.6767          |
| Archaea:Halorubrum (Taxon ID:2247)                                       | Halorubrum                                    | 4.64804         |
| Archaea:Halorubrum distributum (Taxon ID:29283)                          | Halorubrum distributum                        | 3.30737         |
| Archaea:Halorubrum ezzemoulense (Taxon ID:337243)                        | Halorubrum ezzemoulense                       | 4.64804         |
| Archaea:Halorubrum lacusprofundi (Taxon ID:2247)                         | Halorubrum lacusprofundi                      | 3.69258         |
| Archaea:Halorussus (Taxon ID:660515)                                     | Halorussus                                    | 5.23039         |
| Archaea:Marine Group II euryarchaeote (Taxon ID:1131268)                 | Marine Group II euryarchaeote                 | 2.29489         |
| Archaea:Metallosphaera sedula (Taxon ID:43687)                           | Metallosphaera sedula                         | 2.19152         |
| Archaea:Methanobacterium (Taxon ID:2160)                                 | Methanobacterium                              | 3.46637         |
| Archaea:Methanobacterium formicicum (Taxon ID:2162)                      | Methanobacterium formicicum                   | 2.68427         |
| Archaea:Methanobrevibacter arboriphilus (Taxon ID:39441)                 | Methanobrevibacter arboriphilus               | 2.22192         |
| Archaea:Methanobrevibacter (Taxon ID:2172)                               | Methanobrevibacter                            | 2.9372          |
| Archaea:Methanobrevibacter smithii (Taxon ID:2173)                       | Methanobrevibacter smithii                    | 1.85316         |
| Archaea:Methanocalculaceae archaeon (Taxon ID:)                          | Methanocalculaceae archaeon                   | 1.86644         |
| Archaea:Methanococcus maripaludis (Taxon ID:39152)                       | Methanococcus maripaludis                     | 1.7467          |
| Archaea:Methanocorpusculum (Taxon ID:2192)                               | Methanocorpusculum                            | 1.80496         |
| Archaea:Methanoculleus (Taxon ID:2198)                                   | Methanoculleus                                | 2.8593          |
| Archaea:Methanoculleus marisnigri (Taxon ID:2198)                        | Methanoculleus marisnigri                     | 2.4781          |
| Archaea:Methanohalophilus (Taxon ID:2175)                                | Methanohalophilus                             | 2.08889         |
| Archaea:Methanohalophilus portucalensis (Taxon ID:39664)                 | Methanohalophilus portucalensis               | 2.08889         |
| Archaea:Methanolinea (Taxon ID:263906)                                   | Methanolinea                                  | 2.66686         |
| Archaea:Methanolobus (Taxon ID:2220)                                     | Methanolobus                                  | 3.16472         |
| Archaea:Methanomassiliicoccaceae archaeon (Taxon ID:1535962)             | Methanomassiliicoccaceae archaeon             | 2.07745         |
| Archaea:Methanomassiliicoccus (Taxon ID:1080709)                         | Methanomassiliicoccus                         | 2.62023         |
| Archaea:Methanophagales archaeon (Taxon ID:)                             | Methanophagales archaeon                      | 3.18251         |
| Archaea:Methanoregula (Taxon ID:183760)                                  | Methanoregula                                 | 2.90457         |
| Archaea:Methanosaeta harundinacea (Taxon ID:301375)                      | Methanosaeta harundinacea                     | 2.57103         |
| Archaea:Methanosarcina (Taxon ID:2206)                                   | Methanosarcina                                | 5.75149         |
| Archaea:Methanosarcina barkeri (Taxon ID:2208)                           | Methanosarcina barkeri                        | 4.56045         |
| Archaea:Methanosarcinaceae archaeon (Taxon ID:176230)                    | Methanosarcinaceae archaeon                   | 2.46599         |
| Archaea:Methanosarcinales archaeon (Taxon ID:183757)                     | Methanosarcinales archaeon                    | 2.6561          |
| Archaea:Methanosarcina mazei (Taxon ID:2209)                             | Methanosarcina mazei                          | 4.14282         |
| Archaea:Methanosphaera (Taxon ID:2316)                                   | Methanosphaera                                | 2.86809         |
| Archaea:Methanothrix (Taxon ID:2222)                                     | Methanothrix                                  | 3.43709         |
| Archaea:Nanoarchaeota archaeon (Taxon ID:192991)                         | Nanoarchaeota archaeon                        | 1.16224         |
| Archaea:Natrialbaceae archaeon (Taxon ID:1727667)                        | Natrialbaceae archaeon                        | 3.94124         |
| Archaea:Natrinema altunense (Taxon ID:222984)                            | Natrinema altunense                           | 3.77413         |
| Archaea:Natronobacterium gregoryi (Taxon ID:44930)                       | Natronobacterium gregoryi                     | 3.72347         |
| Archaea:Nitrosopumilales archaeon (Taxon ID:171534)                      | Nitrosopumilales archaeon                     | 2.67884         |
| Archaea:Nitrosopumilus (Taxon ID:338191)                                 | Nitrosopumilus                                | 3.44157         |
| Archaea:Nitrososphaera (Taxon ID:497726)                                 | Nitrososphaera                                | 3.14496         |
| Archaea:Saccharolobus solfataricus (Taxon ID:)                           | Saccharolobus solfataricus                    | 3.03402         |
| Archaea:Sulfolobus acidocaldarius (Taxon ID:2285)                        | Sulfolobus acidocaldarius                     | 2.22596         |
| Archaea:Sulfolobus (Taxon ID:2283)                                       | Sulfolobus                                    | 2.73627         |
| Archaea:Sulfolobus islandicus (Taxon ID:43080)                           | Sulfolobus islandicus                         | 2.73627         |
| Archaea:Thaumarchaeota archaeon (Taxon ID:651141)                        | Thaumarchaeota archaeon                       | 3.96945         |
| Archaea:Thermococci archaeon (Taxon ID:376540)                           | Thermococci archaeon                          | 1.65203         |
| Archaea:Thermococcus (Taxon ID:2263)                                     | Thermococcus                                  | 2.36235         |
| Archaea:Thermofilum (Taxon ID:2268)                                      | Thermofilum                                   | 1.88142         |
| Archaea:Thermoplasmata archaeon (Taxon ID:376542)                        | Thermoplasmata archaeon                       | 2.78121         |
| Archaea:Thermoprotei archaeon (Taxon ID:476105)                          | Thermoprotei archaeon                         | 3.54368         |
| Archaea:Thermoproteus (Taxon ID:2270)                                    | Thermoproteus                                 | 1.93606         |
| Archaea:Vulcanisaeta (Taxon ID:164450)                                   | Vulcanisaeta                                  | 2.44388         |
| Archaea:Vulcanisaeta distributa (Taxon ID:164451)                        | Vulcanisaeta distributa                       | 2.42431         |          



| APPENDIX III Adapter Series    |
|--------------------------------|

10x Genomics Linked Reads
10x Genomics scATAC
10x Genomics scDNA
10x Genomics scRNA v2
Agilent Haloplex
Agilent SureSelect XT Methylseq
Agilent SureSelect XT2
Fluidigm
IDT 384 UMI Unique Dual Index
IDT non-UMI Unique Dual Index 
IDT UMI Unique Dual Index
Illumina BioO
Illumina NEBNext small RNA
Illumina Nextera
Illumina Nextera Exome
Illumina Nextera MP
Illumina Nextera XT
Illumina Nextera XT v2
Illumina NuGEN
Illumina TruSeq Amplicon
Illumina TruSeq DNA
Illumina TruSeq HT
Illumina TruSeq RNA
Illumina TruSeq smRNA
NEDNext

## Illumina TruSeq DNA ##
Index_1
Index_2
Index_3
Index_4
Index_5
Index_6
Index_7
Index_8
Index_9
Index_10
Index_11
Index_12
Index_13
Index_14
Index_15
Index_16
Index_18
Index_19
Index_20
Index_21
Index_22
Index_23
Index_25
Index_27

## Illumina TruSeq RNA ##
Index_1
Index_2
Index_3
Index_4
Index_5
Index_6
Index_7
Index_8
Index_9
Index_10
Index_11
Index_12
Index_13
Index_14
Index_15
Index_16
Index_18
Index_19
Index_20
Index_21
Index_22
Index_23
Index_25
Index_27

## Illumina TruSeq smRNA ##
RPI1
RPI2
RPI3
RPI4
RPI5
RPI6
RPI7
RPI8
RPI9
RPI10
RPI11
RPI12
RPI13
RPI14
RPI15
RPI16
RPI17
RPI18
RPI19
RPI20
RPI21
RPI22
RPI23
RPI24
RPI25
RPI26
RPI27
RPI28
RPI29
RPI30
RPI31
RPI32
RPI33
RPI34
RPI35
RPI36
RPI37
RPI38
RPI39
RPI40
RPI41
RPI42
RPI43
RPI44
RPI45
RPI46
RPI47
RPI48

## Illumina Nextera ##
N701-N501
N702-N501
N703-N501
N704-N501
N705-N501
N706-N501
N707-N501
N708-N501
N709-N501
N710-N501
N711-N501
N712-N501
N701-N502
N702-N502
N703-N502
N704-N502
N705-N502
N706-N502
N707-N502
N708-N502
N709-N502
N710-N502
N711-N502
N712-N502
N701-N503
N702-N503
N703-N503
N704-N503
N705-N503
N706-N503
N707-N503
N708-N503
N709-N503
N710-N503
N711-N503
N712-N503
N701-N504
N702-N504
N703-N504
N704-N504
N705-N504
N706-N504
N707-N504
N708-N504
N709-N504
N710-N504
N711-N504
N712-N504
N701-N505
N702-N505
N703-N505
N704-N505
N705-N505
N706-N505
N707-N505
N708-N505
N709-N505
N710-N505
N711-N505
N712-N505
N701-N506
N702-N506
N703-N506
N704-N506
N705-N506
N706-N506
N707-N506
N708-N506
N709-N506
N710-N506
N711-N506
N712-N506
N701-N507
N702-N507
N703-N507
N704-N507
N705-N507
N706-N507
N707-N507
N708-N507
N709-N507
N710-N507
N711-N507
N712-N507
N701-N508
N702-N508
N703-N508
N704-N508
N705-N508
N706-N508
N707-N508
N708-N508
N709-N508
N710-N508
N711-N508
N712-N508

## Illumina Nextera XT ##
N701-S501
N701-S502
N701-S503
N701-S504
N701-S505
N701-S506
N701-S507
N701-S508
N701-S510
N701-S511
N701-S513
N701-S515
N701-S516
N701-S517
N701-S518
N701-S520
N701-S521
N701-S522
N702-S501
N702-S502
N702-S503
N702-S504
N702-S505
N702-S506
N702-S507
N702-S508
N702-S510
N702-S511
N702-S513
N702-S515
N702-S516
N702-S517
N702-S518
N702-S520
N702-S521
N702-S522
N703-S501
N703-S502
N703-S503
N703-S504
N703-S505
N703-S506
N703-S507
N703-S508
N703-S510
N703-S511
N703-S513
N703-S515
N703-S516
N703-S517
N703-S518
N703-S520
N703-S521
N703-S522
N704-S501
N704-S502
N704-S503
N704-S504
N704-S505
N704-S506
N704-S507
N704-S508
N704-S510
N704-S511
N704-S513
N704-S515
N704-S516
N704-S517
N704-S518
N704-S520
N704-S521
N704-S522
N705-S501
N705-S502
N705-S503
N705-S504
N705-S505
N705-S506
N705-S507
N705-S508
N705-S510
N705-S511
N705-S513
N705-S515
N705-S516
N705-S517
N705-S518
N705-S520
N705-S521
N705-S522
N706-S501
N706-S502
N706-S503
N706-S504
N706-S505
N706-S506

## Illumina TruSeq HT ##
D701-D501
D701-D502
D701-D503
D701-D504
D701-D505
D701-D506
D701-D507
D701-D508
D702-D501
D702-D502
D702-D503
D702-D504
D702-D505
D702-D506
D702-D507
D702-D508
D703-D501
D703-D502
D703-D503
D703-D504
D703-D505
D703-D506
D703-D507
D703-D508
D704-D501
D704-D502
D704-D503
D704-D504
D704-D505
D704-D506
D704-D507
D704-D508
D705-D501
D705-D502
D705-D503
D705-D504
D705-D505
D705-D506
D705-D507
D705-D508
D706-D501
D706-D502
D706-D503
D706-D504
D706-D505
D706-D506
D706-D507
D706-D508
D707-D501
D707-D502
D707-D503
D707-D504
D707-D505
D707-D506
D707-D507
D707-D508
D708-D501
D708-D502
D708-D503
D708-D504
D708-D505
D708-D506
D708-D507
D708-D508
D709-D501
D709-D502
D709-D503
D709-D504
D709-D505
D709-D506
D709-D507
D709-D508
D710-D501
D710-D502
D710-D503
D710-D504
D710-D505
D710-D506
D710-D507
D710-D508
D711-D501
D711-D502
D711-D503
D711-D504
D711-D505
D711-D506
D711-D507
D711-D508
D712-D501
D712-D502
D712-D503
D712-D504
D712-D505
D712-D506
D712-D507
D712-D508

## IDT non-UMI Unique Dual Index ##
IDT701-IDT501
IDT702-IDT502
IDT703-IDT503
IDT704-IDT504
IDT705-IDT505
IDT706-IDT506
IDT707-IDT507
IDT708-IDT508
IDT709-IDT509
IDT710-IDT510
IDT711-IDT511
IDT712-IDT512
IDT713-IDT513
IDT714-IDT514
IDT715-IDT515
IDT716-IDT516
IDT717-IDT517
IDT718-IDT518
IDT719-IDT519
IDT720-IDT520
IDT721-IDT521
IDT722-IDT522
IDT723-IDT523
IDT724-IDT524
IDT725-IDT525
IDT726-IDT526
IDT727-IDT527
IDT728-IDT528
IDT729-IDT529
IDT730-IDT530
IDT731-IDT531
IDT732-IDT532
IDT733-IDT533
IDT734-IDT534
IDT735-IDT535
IDT736-IDT536
IDT737-IDT537
IDT738-IDT538
IDT739-IDT539
IDT740-IDT540
IDT741-IDT541
IDT742-IDT542
IDT743-IDT543
IDT744-IDT544
IDT745-IDT545
IDT746-IDT546
IDT747-IDT547
IDT748-IDT548
IDT749-IDT549
IDT750-IDT550
IDT751-IDT551
IDT752-IDT552
IDT753-IDT553
IDT754-IDT554
IDT755-IDT555
IDT756-IDT556
IDT757-IDT557
IDT758-IDT558
IDT759-IDT559
IDT760-IDT560
IDT761-IDT561
IDT762-IDT562
IDT763-IDT563
IDT764-IDT564
IDT765-IDT565
IDT766-IDT566
IDT767-IDT567
IDT768-IDT568
IDT769-IDT569
IDT770-IDT570
IDT771-IDT571
IDT772-IDT572
IDT773-IDT573
IDT774-IDT574
IDT775-IDT575
IDT776-IDT576
IDT777-IDT577
IDT778-IDT578
IDT779-IDT579
IDT780-IDT580
IDT781-IDT581
IDT782-IDT582
IDT783-IDT583
IDT784-IDT584
IDT785-IDT585
IDT786-IDT586
IDT787-IDT587
IDT788-IDT588
IDT789-IDT589
IDT790-IDT590
IDT791-IDT591
IDT792-IDT592
IDT793-IDT593
IDT794-IDT594
IDT795-IDT595
IDT796-IDT596

## IDT UMI Unique Dual Index ##
IDTU701-IDTU501
IDTU702-IDTU502
IDTU703-IDTU503
IDTU704-IDTU504
IDTU705-IDTU505
IDTU706-IDTU506
IDTU707-IDTU507
IDTU708-IDTU508
IDTU709-IDTU509
IDTU710-IDTU510
IDTU711-IDTU511
IDTU712-IDTU512
IDTU713-IDTU513
IDTU714-IDTU514
IDTU715-IDTU515
IDTU716-IDTU516
IDTU717-IDTU517
IDTU718-IDTU518
IDTU719-IDTU519
IDTU720-IDTU520
IDTU721-IDTU521
IDTU722-IDTU522
IDTU723-IDTU523
IDTU724-IDTU524
IDTU725-IDTU525
IDTU726-IDTU526
IDTU727-IDTU527
IDTU728-IDTU528
IDTU729-IDTU529
IDTU730-IDTU530
IDTU731-IDTU531
IDTU732-IDTU532
IDTU733-IDTU533
IDTU734-IDTU534
IDTU735-IDTU535
IDTU736-IDTU536
IDTU737-IDTU537
IDTU738-IDTU538
IDTU739-IDTU539
IDTU740-IDTU540
IDTU741-IDTU541
IDTU742-IDTU542
IDTU743-IDTU543
IDTU744-IDTU544
IDTU745-IDTU545
IDTU746-IDTU546
IDTU747-IDTU547
IDTU748-IDTU548
IDTU749-IDTU549
IDTU750-IDTU550
IDTU751-IDTU551
IDTU752-IDTU552
IDTU753-IDTU553
IDTU754-IDTU554
IDTU755-IDTU555
IDTU756-IDTU556
IDTU757-IDTU557
IDTU758-IDTU558
IDTU759-IDTU559
IDTU760-IDTU560
IDTU761-IDTU561
IDTU762-IDTU562
IDTU763-IDTU563
IDTU764-IDTU564
IDTU765-IDTU565
IDTU766-IDTU566
IDTU767-IDTU567
IDTU768-IDTU568
IDTU769-IDTU569
IDTU770-IDTU570
IDTU771-IDTU571
IDTU772-IDTU572
IDTU773-IDTU573
IDTU774-IDTU574
IDTU775-IDTU575
IDTU776-IDTU576
IDTU777-IDTU577
IDTU778-IDTU578
IDTU779-IDTU579
IDTU780-IDTU580
IDTU781-IDTU581
IDTU782-IDTU582
IDTU783-IDTU583
IDTU784-IDTU584
IDTU785-IDTU585
IDTU786-IDTU586
IDTU787-IDTU587
IDTU788-IDTU588
IDTU789-IDTU589
IDTU790-IDTU590
IDTU791-IDTU591
IDTU792-IDTU592
IDTU793-IDTU593
IDTU794-IDTU594
IDTU795-IDTU595
IDTU796-IDTU596

## IDT 384 UMI Unique Dual Index ##
IDTU7001-IDTU5001
IDTU7002-IDTU5002
IDTU7003-IDTU5003
IDTU7004-IDTU5004
IDTU7005-IDTU5005
IDTU7006-IDTU5006
IDTU7007-IDTU5007
IDTU7008-IDTU5008
IDTU7009-IDTU5009
IDTU7010-IDTU5010
IDTU7011-IDTU5011
IDTU7012-IDTU5012
IDTU7013-IDTU5013
IDTU7014-IDTU5014
IDTU7015-IDTU5015
IDTU7016-IDTU5016
IDTU7017-IDTU5017
IDTU7018-IDTU5018
IDTU7019-IDTU5019
IDTU7020-IDTU5020
IDTU7021-IDTU5021
IDTU7022-IDTU5022
IDTU7023-IDTU5023
IDTU7024-IDTU5024
IDTU7025-IDTU5025
IDTU7026-IDTU5026
IDTU7027-IDTU5027
IDTU7028-IDTU5028
IDTU7029-IDTU5029
IDTU7030-IDTU5030
IDTU7031-IDTU5031
IDTU7032-IDTU5032
IDTU7033-IDTU5033
IDTU7034-IDTU5034
IDTU7035-IDTU5035
IDTU7036-IDTU5036
IDTU7037-IDTU5037
IDTU7038-IDTU5038
IDTU7039-IDTU5039
IDTU7040-IDTU5040
IDTU7041-IDTU5041
IDTU7042-IDTU5042
IDTU7043-IDTU5043
IDTU7044-IDTU5044
IDTU7045-IDTU5045
IDTU7046-IDTU5046
IDTU7047-IDTU5047
IDTU7048-IDTU5048
IDTU7049-IDTU5049
IDTU7050-IDTU5050
IDTU7051-IDTU5051
IDTU7052-IDTU5052
IDTU7053-IDTU5053
IDTU7054-IDTU5054
IDTU7055-IDTU5055
IDTU7056-IDTU5056
IDTU7057-IDTU5057
IDTU7058-IDTU5058
IDTU7059-IDTU5059
IDTU7060-IDTU5060
IDTU7061-IDTU5061
IDTU7062-IDTU5062
IDTU7063-IDTU5063
IDTU7064-IDTU5064
IDTU7065-IDTU5065
IDTU7066-IDTU5066
IDTU7067-IDTU5067
IDTU7068-IDTU5068
IDTU7069-IDTU5069
IDTU7070-IDTU5070
IDTU7071-IDTU5071
IDTU7072-IDTU5072
IDTU7073-IDTU5073
IDTU7074-IDTU5074
IDTU7075-IDTU5075
IDTU7076-IDTU5076
IDTU7077-IDTU5077
IDTU7078-IDTU5078
IDTU7079-IDTU5079
IDTU7080-IDTU5080
IDTU7081-IDTU5081
IDTU7082-IDTU5082
IDTU7083-IDTU5083
IDTU7084-IDTU5084
IDTU7085-IDTU5085
IDTU7086-IDTU5086
IDTU7087-IDTU5087
IDTU7088-IDTU5088
IDTU7089-IDTU5089
IDTU7090-IDTU5090
IDTU7091-IDTU5091
IDTU7092-IDTU5092
IDTU7093-IDTU5093
IDTU7094-IDTU5094
IDTU7095-IDTU5095
IDTU7096-IDTU5096
IDTU7097-IDTU5097
IDTU7098-IDTU5098
IDTU7099-IDTU5099
IDTU7100-IDTU5100
IDTU7101-IDTU5101
IDTU7102-IDTU5102
IDTU7103-IDTU5103
IDTU7104-IDTU5104
IDTU7105-IDTU5105
IDTU7106-IDTU5106
IDTU7107-IDTU5107
IDTU7108-IDTU5108
IDTU7109-IDTU5109
IDTU7110-IDTU5110
IDTU7111-IDTU5111
IDTU7112-IDTU5112
IDTU7113-IDTU5113
IDTU7114-IDTU5114
IDTU7115-IDTU5115
IDTU7116-IDTU5116
IDTU7117-IDTU5117
IDTU7118-IDTU5118
IDTU7119-IDTU5119
IDTU7120-IDTU5120
IDTU7121-IDTU5121
IDTU7122-IDTU5122
IDTU7123-IDTU5123
IDTU7124-IDTU5124
IDTU7125-IDTU5125
IDTU7126-IDTU5126
IDTU7127-IDTU5127
IDTU7128-IDTU5128
IDTU7129-IDTU5129
IDTU7130-IDTU5130
IDTU7131-IDTU5131
IDTU7132-IDTU5132
IDTU7133-IDTU5133
IDTU7134-IDTU5134
IDTU7135-IDTU5135
IDTU7136-IDTU5136
IDTU7137-IDTU5137
IDTU7138-IDTU5138
IDTU7139-IDTU5139
IDTU7140-IDTU5140
IDTU7141-IDTU5141
IDTU7142-IDTU5142
IDTU7143-IDTU5143
IDTU7144-IDTU5144
IDTU7145-IDTU5145
IDTU7146-IDTU5146
IDTU7147-IDTU5147
IDTU7148-IDTU5148
IDTU7149-IDTU5149
IDTU7150-IDTU5150
IDTU7151-IDTU5151
IDTU7152-IDTU5152
IDTU7153-IDTU5153
IDTU7154-IDTU5154
IDTU7155-IDTU5155
IDTU7156-IDTU5156
IDTU7157-IDTU5157
IDTU7158-IDTU5158
IDTU7159-IDTU5159
IDTU7160-IDTU5160
IDTU7161-IDTU5161
IDTU7162-IDTU5162
IDTU7163-IDTU5163
IDTU7164-IDTU5164
IDTU7165-IDTU5165
IDTU7166-IDTU5166
IDTU7167-IDTU5167
IDTU7168-IDTU5168
IDTU7169-IDTU5169
IDTU7170-IDTU5170
IDTU7171-IDTU5171
IDTU7172-IDTU5172
IDTU7173-IDTU5173
IDTU7174-IDTU5174
IDTU7175-IDTU5175
IDTU7176-IDTU5176
IDTU7177-IDTU5177
IDTU7178-IDTU5178
IDTU7179-IDTU5179
IDTU7180-IDTU5180
IDTU7181-IDTU5181
IDTU7182-IDTU5182
IDTU7183-IDTU5183
IDTU7184-IDTU5184
IDTU7185-IDTU5185
IDTU7186-IDTU5186
IDTU7187-IDTU5187
IDTU7188-IDTU5188
IDTU7189-IDTU5189
IDTU7190-IDTU5190
IDTU7191-IDTU5191
IDTU7192-IDTU5192
IDTU7193-IDTU5193
IDTU7194-IDTU5194
IDTU7195-IDTU5195
IDTU7196-IDTU5196
IDTU7197-IDTU5197
IDTU7198-IDTU5198
IDTU7199-IDTU5199
IDTU7200-IDTU5200
IDTU7201-IDTU5201
IDTU7202-IDTU5202
IDTU7203-IDTU5203
IDTU7204-IDTU5204
IDTU7205-IDTU5205
IDTU7206-IDTU5206
IDTU7207-IDTU5207
IDTU7208-IDTU5208
IDTU7209-IDTU5209
IDTU7210-IDTU5210
IDTU7211-IDTU5211
IDTU7212-IDTU5212
IDTU7213-IDTU5213
IDTU7214-IDTU5214
IDTU7215-IDTU5215
IDTU7216-IDTU5216
IDTU7217-IDTU5217
IDTU7218-IDTU5218
IDTU7219-IDTU5219
IDTU7220-IDTU5220
IDTU7221-IDTU5221
IDTU7222-IDTU5222
IDTU7223-IDTU5223
IDTU7224-IDTU5224
IDTU7225-IDTU5225
IDTU7226-IDTU5226
IDTU7227-IDTU5227
IDTU7228-IDTU5228
IDTU7229-IDTU5229
IDTU7230-IDTU5230
IDTU7231-IDTU5231
IDTU7232-IDTU5232
IDTU7233-IDTU5233
IDTU7234-IDTU5234
IDTU7235-IDTU5235
IDTU7236-IDTU5236
IDTU7237-IDTU5237
IDTU7238-IDTU5238
IDTU7239-IDTU5239
IDTU7240-IDTU5240
IDTU7241-IDTU5241
IDTU7242-IDTU5242
IDTU7243-IDTU5243
IDTU7244-IDTU5244
IDTU7245-IDTU5245
IDTU7246-IDTU5246
IDTU7247-IDTU5247
IDTU7248-IDTU5248
IDTU7249-IDTU5249
IDTU7250-IDTU5250
IDTU7251-IDTU5251
IDTU7252-IDTU5252
IDTU7253-IDTU5253
IDTU7254-IDTU5254
IDTU7255-IDTU5255
IDTU7256-IDTU5256
IDTU7257-IDTU5257
IDTU7258-IDTU5258
IDTU7259-IDTU5259
IDTU7260-IDTU5260
IDTU7261-IDTU5261
IDTU7262-IDTU5262
IDTU7263-IDTU5263
IDTU7264-IDTU5264
IDTU7265-IDTU5265
IDTU7266-IDTU5266
IDTU7267-IDTU5267
IDTU7268-IDTU5268
IDTU7269-IDTU5269
IDTU7270-IDTU5270
IDTU7271-IDTU5271
IDTU7272-IDTU5272
IDTU7273-IDTU5273
IDTU7274-IDTU5274
IDTU7275-IDTU5275
IDTU7276-IDTU5276
IDTU7277-IDTU5277
IDTU7278-IDTU5278
IDTU7279-IDTU5279
IDTU7280-IDTU5280
IDTU7281-IDTU5281
IDTU7282-IDTU5282
IDTU7283-IDTU5283
IDTU7284-IDTU5284
IDTU7285-IDTU5285
IDTU7286-IDTU5286
IDTU7287-IDTU5287
IDTU7288-IDTU5288
IDTU7289-IDTU5289
IDTU7290-IDTU5290
IDTU7291-IDTU5291
IDTU7292-IDTU5292
IDTU7293-IDTU5293
IDTU7294-IDTU5294
IDTU7295-IDTU5295
IDTU7296-IDTU5296
IDTU7297-IDTU5297
IDTU7298-IDTU5298
IDTU7299-IDTU5299
IDTU7300-IDTU5300
IDTU7301-IDTU5301
IDTU7302-IDTU5302
IDTU7303-IDTU5303
IDTU7304-IDTU5304
IDTU7305-IDTU5305
IDTU7306-IDTU5306
IDTU7307-IDTU5307
IDTU7308-IDTU5308
IDTU7309-IDTU5309
IDTU7310-IDTU5310
IDTU7311-IDTU5311
IDTU7312-IDTU5312
IDTU7313-IDTU5313
IDTU7314-IDTU5314
IDTU7315-IDTU5315
IDTU7316-IDTU5316
IDTU7317-IDTU5317
IDTU7318-IDTU5318
IDTU7319-IDTU5319
IDTU7320-IDTU5320
IDTU7321-IDTU5321
IDTU7322-IDTU5322
IDTU7323-IDTU5323
IDTU7324-IDTU5324
IDTU7325-IDTU5325
IDTU7326-IDTU5326
IDTU7327-IDTU5327
IDTU7328-IDTU5328
IDTU7329-IDTU5329
IDTU7330-IDTU5330
IDTU7331-IDTU5331
IDTU7332-IDTU5332
IDTU7333-IDTU5333
IDTU7334-IDTU5334
IDTU7335-IDTU5335
IDTU7336-IDTU5336
IDTU7337-IDTU5337
IDTU7338-IDTU5338
IDTU7339-IDTU5339
IDTU7340-IDTU5340
IDTU7341-IDTU5341
IDTU7342-IDTU5342
IDTU7343-IDTU5343
IDTU7344-IDTU5344
IDTU7345-IDTU5345
IDTU7346-IDTU5346
IDTU7347-IDTU5347
IDTU7348-IDTU5348
IDTU7349-IDTU5349
IDTU7350-IDTU5350
IDTU7351-IDTU5351
IDTU7352-IDTU5352
IDTU7353-IDTU5353
IDTU7354-IDTU5354
IDTU7355-IDTU5355
IDTU7356-IDTU5356
IDTU7357-IDTU5357
IDTU7358-IDTU5358
IDTU7359-IDTU5359
IDTU7360-IDTU5360
IDTU7361-IDTU5361
IDTU7362-IDTU5362
IDTU7363-IDTU5363
IDTU7364-IDTU5364
IDTU7365-IDTU5365
IDTU7366-IDTU5366
IDTU7367-IDTU5367
IDTU7368-IDTU5368
IDTU7369-IDTU5369
IDTU7370-IDTU5370
IDTU7371-IDTU5371
IDTU7372-IDTU5372
IDTU7373-IDTU5373
IDTU7374-IDTU5374
IDTU7375-IDTU5375
IDTU7376-IDTU5376
IDTU7377-IDTU5377
IDTU7378-IDTU5378
IDTU7379-IDTU5379
IDTU7380-IDTU5380
IDTU7381-IDTU5381
IDTU7382-IDTU5382
IDTU7383-IDTU5383
IDTU7384-IDTU5384
