
#============TRAINING PARAMETERS==============
local batch_size = 1; # adjust this to fit the memory capacity of your machine (mostly GPU memory is relevant)
local num_epochs = 1; # we recommend 40-100 epochs on real datasets and 200 epochs for toy datasets, but your optimal parameters may differ
local patience = 1000; # this is per default set to 1000 to turn off early stopping.
local evaluate_on_test = false; # Whether to evaluate on the test set.


#============FILEPATHS==============
local train_zip_path = "example/minimalAMRAutomata/train.zip";  
local dev_zip_path = "example/minimalAMRAutomata/train.zip";
local validation_amconll_path = "example/minimalAMRAutomata/corpus.amconll";
local validation_gold_path = "example/minimalAMRAutomata/gold.txt";
local test_amconll_path = "";
local test_gold_path = "";


#=============IMPORTING MODEL AND FORMALISM CONFIGS==================
local formalism_config = import '../formalisms/AMR.libsonnet';

local raw_model_config = import '../models/toy.libsonnet';





#==================PUTTING IT ALL TOGETHER (DO NOT MODIFY) ===================
# This puts everyting above together. You should not need to modify anything below this line

# Putting the parameters of this file and the formalism config into the model config file (this is necessary due to how the jsonnet structures are organized/nested)
local model_config = raw_model_config(batch_size, num_epochs, patience, formalism_config['task'], formalism_config['evaluation_command'], formalism_config['validation_metric'], validation_amconll_path, validation_gold_path, test_amconll_path, test_gold_path);

# Now we can write down all of the actual config entries
{
	"dataset_reader": model_config['dataset_reader'],
    "iterator": model_config['iterator'],
    "vocabulary" : model_config['vocabulary'],
    "model":  model_config['model'],
	
    "train_data_path": [ [formalism_config['task'], train_zip_path]],
    "validation_data_path": [ [formalism_config['task'], dev_zip_path]],


    #=========================EVALUATE ON TEST=================================
    "evaluate_on_test" : evaluate_on_test,
    "test_evaluators" : model_config['test_evaluators'],
    #==========================================================================

    "trainer" : model_config['trainer'],
}

