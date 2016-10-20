use strict;
use Getopt::Long;

my $WORK_DIR;
my $DEV_SRC;
my $DEV_REF;
my $DICT_SRC;
my $DICT_TRG;
my $MODEL;
my $AMUN;
my $DEVICE = 0;

GetOptions(
    'work-dir=s' => \$WORK_DIR,
	'dev-src=s' => \$DEV_SRC,
	'dev-trg=s' => \$DEV_REF,
	'amun=s' => \$AMUN,
	'model=s' => \$MODEL,
	'dict-src=s' => \$DICT_SRC,
	'dict-trg=s' => \$DICT_TRG,
	'device=s' => \$DEVICE
);

if($DEVICE =~ /gpu(\d)/) {
  $DEVICE = $1;
}

print <<END
#!/bin/bash

dev=$DEV_SRC
ref=$DEV_REF

# decode
cat $DEV_SRC | $AMUN -m $MODEL -s $DICT_SRC -t $DICT_TRG -n -b 12 -d $DEVICE | perl -pe 's/\@\@ //g' > $DEV_SRC.output

## get BLEU
BEST=`cat $WORK_DIR/best_bleu || echo 0`
BLEU=`perl scripts/multi-bleu.perl <(cat $DEV_REF | perl -pe 's/\@\@ //g') < $DEV_SRC.output | cut -f 3 -d ' ' | cut -f 1 -d ','`
echo \$BLEU >> $WORK_DIR/bleu_scores
BETTER=`echo "\$BLEU > \$BEST" | bc`

echo "BLEU = \$BLEU"

if [ "\$BETTER" = "1" ]; then
  echo "new best; saving"
  echo \$BLEU > $WORK_DIR/best_bleu
  cp $MODEL $MODEL.best_bleu
fi
END
