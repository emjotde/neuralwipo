import numpy
import os
import argparse

parser = argparse.ArgumentParser(description='Options')
parser.add_argument('-f','--train.src', help='Description for foo argument', required=True)
parser.add_argument('-e','--train.trg', help='Description for bar argument', required=True)
parser.add_argument('--dict.src', help='Description for foo argument', required=True)
parser.add_argument('--dict.trg', help='Description for bar argument', required=True)
parser.add_argument('--valid.src', help='Description for foo argument', required=True)
parser.add_argument('--valid.trg', help='Description for bar argument', required=True)
parser.add_argument('--work.dir', help='Description for bar argument', required=True)
parser.add_argument('--valid.script', help='Description for bar argument', required=True)
config = vars(parser.parse_args())

from nematus.nmt import train

if __name__ == '__main__':
    train(saveto= config['work.dir'] + '/' + 'model.npz',
        reload_=True,
        dim_word=500,
        dim=1024,
        n_words_src=50000,
        n_words=50000,
        decay_c=0.,
        clip_c=1.,
        lrate=0.0001,
        optimizer='adam',
        maxlen=100,
        batch_size=40,
        valid_batch_size=40,
        datasets=[config["train.src"], config["train.trg"]],
        valid_datasets=[config["valid.src"], config["valid.trg"]],
        dictionaries=[config["dict.src"], config["dict.trg"]],
        validFreq=10000,
        dispFreq=1000,
        saveFreq=10000,
        sampleFreq=10000,
        use_dropout=True,
        max_epochs=5,
        shuffle_each_epoch=True,
        dropout_embedding=0.1, # dropout for input embeddings (0: no dropout)
        dropout_hidden=0.1, # dropout for hidden layers (0: no dropout)
        dropout_source=0.1, # dropout source words (0: no dropout)
        dropout_target=0.1, # dropout target words (0: no dropout)
        overwrite=False,
        external_validation_script=config["valid.script"])
