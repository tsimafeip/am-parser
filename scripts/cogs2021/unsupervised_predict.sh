#!/usr/bin bash
##
## Copyright (c) 2021 Saarland University.
##
## This file is part of AM Parser
## (see https://github.com/coli-saar/am-parser/).
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
# see also : predict.sh in main folder
# heavily copied todo rather modify predict.sh?
# COGS specific for now
# bash ./scripts/cogs2021/unsupervised_predict.sh -i ../cogs2021/small/test5.tsv -o ../cogs2021/output -m ../cogs2021/temp/model.tar.gz -g 0 -f &> ../cogs2021/predict-sh.log

type="COGS"

jar="am-tools.jar"

# Documenting parameters:
usage="Takes . \n\n

Required arguments: \n
\n\t     -i  input file:  Graph corpus in the original format. For COGS this is .tsv format
\n\t     -o  output folder: where the results will be stored.

\noptions:

\n\t   -m  archived model file in .tar.gz format.
\n\t   -f  faster, less accurate evaluation (flag; default false)
\n\t   -g  which gpu to use (its ID, i.e. 0, 1 or 2 etc). Default is -1, using CPU instead"

#defaults:
fast=false
gpu="-1"
# Gathering parameters:
while getopts "m:i:o:T:g:fh" opt; do
    case $opt in
  h) echo -e $usage
     exit
     ;;
  m) model="$OPTARG"
     ;;
  i) input="$OPTARG"
     ;;
  o) output="$OPTARG"
     ;;
  T) type="$OPTARG"
     ;;
  g) gpu="$OPTARG"
     ;;
  f) fast=true
     ;;
  \?) echo "Invalid option -$OPTARG" >&2
      ;;
    esac
done

if [ "$gpu" = "-1" ]; then
    echo "Warning: using CPU, this may be slow. Use -g to specify a GPU ID"
fi

if [ -f "$model" ]; then
    echo "model file found at $model"
else
    echo "model not found at $model. Please check the -m parameter"
    exit 1
fi

if [ -f "$jar" ]; then
    printf "jar file found at $jar"
else
    echo "jar file not found at $jar."
    exit 1
fi

if [ "$input" = "" ]; then
    printf "\n No input file given. Please use -i option.\n"
    exit 1
fi

if [ "$output" = "" ]; then
    printf "\n No output folder path given. Please use -o option.\n"
    exit 1
fi

# Finished gathering parameters. We are now guaranteed to have the necessary arguments stored in the right place.
echo "Parsing input file $input with model $model to $type graphs, output in $output"

# create filename for amconll file
output=$output"/"
prefix=$type"_gold"
amconll_input=$output$prefix".amconll" # used as input for neural model, but we must create it first
amconll_prediction=$output$type"_pred.amconll" # where the neural model writes its prediction

# convert input file to AMConLL format
echo "--> Convert input file to AMConLL format ..."
java -cp $jar de.saar.coli.amrtagging.formalisms.cogs.tools.PrepareDevData -c $input -o $output -p $prefix

# run neural net + fixed-tree decoder to obtain AMConLL file. Pass the --give_up option if we want things to run faster.
# (pw: opened a github issue that using one thread seems to be faster and idk why, therefore using --thread 1 here)
echo "--> Predicting (fast? $fast)..."
if [ "$fast" = "false" ]; then
    python3 parse_file.py $model $type $amconll_input $amconll_prediction --cuda-device $gpu --threads 1
else
    python3 parse_file.py $model $type $amconll_input $amconll_prediction --cuda-device $gpu --threads 1 --give_up 15
fi

echo "--> Done with predicting at time:"
date
# convert AMConLL file (consisting of AM dependency trees) to final output file (containing graphs in the representation-specific format)
# and evaluate
echo "--> converting AMConLL to final output file .."
java -cp $jar de.saar.coli.amrtagging.formalisms.cogs.tools.ToCOGSCorpus -c "$amconll_prediction" -o "$output$type""_pred.tsv" --gold "$input" --verbose

echo "--> DONE!"
# THE END
