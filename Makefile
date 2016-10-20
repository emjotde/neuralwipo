SHELL=/bin/bash
.SUFFIXES:
.SECONDARY:
.DELETE_ON_ERROR:

dir_guard=@mkdir -p $(@D)

GPU=gpu0
CODES=50000
SRC=zh
TRG=en
SUFFIX=en-zh
MAXLENGTH=100

MOSES=/data/smt/mosesdecoder
TOK=$(MOSES)/scripts/tokenizer
TRN=$(MOSES)/scripts/training
BPE=scripts
NMT=scripts
PARALLEL=parallel --pipe -k -j16 --block 100M
AMUN=/data/smt/amunmt/build/bin

all : train

### PREPROCESSING ###

$(SRC)-$(TRG)/%.proc.all : /data/smt/Corpora/all.$(SUFFIX)/%.$(SRC) /data/smt/Corpora/all.$(SUFFIX)/%.$(TRG) /data/smt/Corpora/all.$(SUFFIX)/%.xx
	$(dir_guard)
	paste $^ | $(PARALLEL) "perl scripts/addTagsAndYearForNmt.pl | perl scripts/unique.pl" 2>/dev/null > $@

$(SRC)-$(TRG)/%.proc.$(SRC) : $(SRC)-$(TRG)/%.proc.all
	$(dir_guard)
	cat $^ | cut -f 1 > $@

$(SRC)-$(TRG)/%.proc.$(TRG) : $(SRC)-$(TRG)/%.proc.all
	$(dir_guard)
	cat $^ | cut -f 2 > $@

$(SRC)-$(TRG)/bpe-codes.$(SRC) : $(SRC)-$(TRG)/trainset.proc.$(SRC)
	$(dir_guard)
	cat $^ | $(BPE)/learn_bpe.py -s $(CODES) > $@

$(SRC)-$(TRG)/bpe-codes.$(TRG) : $(SRC)-$(TRG)/trainset.proc.$(TRG)
	$(dir_guard)
	cat $^ | $(BPE)/learn_bpe.py -s $(CODES) > $@

$(SRC)-$(TRG)/%.proc.bpe.$(SRC) : $(SRC)-$(TRG)/%.proc.$(SRC) $(SRC)-$(TRG)/bpe-codes.$(SRC)
	$(dir_guard)
	cat $< | $(PARALLEL) $(BPE)/apply_bpe.py -c $(SRC)-$(TRG)/bpe-codes.$(SRC) > $@

$(SRC)-$(TRG)/%.proc.bpe.$(TRG) : $(SRC)-$(TRG)/%.proc.$(TRG) $(SRC)-$(TRG)/bpe-codes.$(TRG)
	$(dir_guard)
	cat $< | $(PARALLEL) $(BPE)/apply_bpe.py -c $(SRC)-$(TRG)/bpe-codes.$(TRG) > $@

### TRAINING ###

%.json : %
	python scripts/build_dictionary.py $^

$(SRC)-$(TRG)/validate.sh :
	$(dir_guard)
	perl scripts/create_validate.pl \
	  --work-dir $(SRC)-$(TRG) \
	  --dev-src $(SRC)-$(TRG)/devset.proc.bpe.$(SRC) \
	  --dev-trg $(SRC)-$(TRG)/devset.proc.bpe.$(TRG) \
	  --amun $(AMUN)/amun --device $(GPU) \
	  --model $(SRC)-$(TRG)/model.npz.dev.npz \
	  --dict-src $(SRC)-$(TRG)/trainset.proc.bpe.$(SRC).json \
	  --dict-trg $(SRC)-$(TRG)/trainset.proc.bpe.$(TRG).json \
	> $@
	chmod a+x $@

train: \
	$(SRC)-$(TRG)/trainset.proc.bpe.$(SRC) \
	$(SRC)-$(TRG)/trainset.proc.bpe.$(SRC).json \
	$(SRC)-$(TRG)/trainset.proc.bpe.$(TRG) \
	$(SRC)-$(TRG)/trainset.proc.bpe.$(TRG).json \
	$(SRC)-$(TRG)/devset.proc.bpe.$(TRG) \
	$(SRC)-$(TRG)/devset.proc.bpe.$(SRC) \
	$(SRC)-$(TRG)/testset.proc.bpe.$(TRG) \
	$(SRC)-$(TRG)/testset.proc.bpe.$(SRC) \
	$(SRC)-$(TRG)/validate.sh
	$(dir_guard)
	THEANO_FLAGS=device=$(GPU),floatX=float32 \
	python scripts/train_nmt_args.py \
	--train.src $(SRC)-$(TRG)/trainset.proc.bpe.$(SRC) \
	--train.trg $(SRC)-$(TRG)/trainset.proc.bpe.$(TRG) \
	--valid.src $(SRC)-$(TRG)/devset.proc.bpe.$(SRC) \
	--valid.trg $(SRC)-$(TRG)/devset.proc.bpe.$(TRG) \
	--dict.src $(SRC)-$(TRG)/trainset.proc.bpe.$(SRC).json \
	--dict.trg $(SRC)-$(TRG)/trainset.proc.bpe.$(TRG).json \
	--work.dir $(SRC)-$(TRG) \
	--valid.script $(SRC)-$(TRG)/validate.sh
