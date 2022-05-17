#!/usr/bin/env bash
# Copyright (c) 2019-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.
#

set -e

#
# Data preprocessing configuration
#
# N_MONO=5000000  # 5M: number of monolingual sentences for each language
N_MONO=50000000 # 50M: number of monolingual sentences for each language (this should be better)

#
# Read arguments
#
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
  --src)
    SRC="$2"; shift 2;;
  --tgt)
    TGT="$2"; shift 2;;
  *)
  POSITIONAL+=("$1")
  shift
  ;;
esac
done
set -- "${POSITIONAL[@]}"


#
# Check parameters
#
if [ "$SRC" == "" ]; then echo "--src not provided"; exit; fi
if [ "$TGT" == "" ]; then echo "--tgt not provided"; exit; fi
if [ "$SRC" == "$TGT" ]; then echo "source and target cannot be identical"; exit; fi

# main paths
MAIN_PATH=$PWD
TOOLS_PATH=$PWD/tools
DATA_PATH=$MAIN_PATH/data
MONO_PATH=$DATA_PATH/mono
PARA_PATH=$DATA_PATH/para
PARA_PATH_BILINGUAL=$DATA_PATH/para/$SRC-$TGT

# raw data paths
SRC_RAW=$MONO_PATH/$SRC/train_raw.$SRC
TGT_RAW=$MONO_PATH/$TGT/train_raw.$TGT
PARA_SRC_VALID_RAW=$PARA_PATH_BILINGUAL/valid_raw.$SRC
PARA_TGT_VALID_RAW=$PARA_PATH_BILINGUAL/valid_raw.$TGT
PARA_SRC_TEST_RAW=$PARA_PATH_BILINGUAL/test_raw.$SRC
PARA_TGT_TEST_RAW=$PARA_PATH_BILINGUAL/test_raw.$TGT

mkdir -p $DATA_PATH
mkdir -p $TOOLS_PATH
mkdir -p $MONO_PATH
mkdir -p $PARA_PATH
mkdir -p $PARA_PATH_BILINGUAL

# moses
MOSES=$TOOLS_PATH/mosesdecoder
REPLACE_UNICODE_PUNCT=$MOSES/scripts/tokenizer/replace-unicode-punctuation.perl
NORM_PUNC=$MOSES/scripts/tokenizer/normalize-punctuation.perl
REM_NON_PRINT_CHAR=$MOSES/scripts/tokenizer/remove-non-printing-char.perl
TOKENIZER=$MOSES/scripts/tokenizer/tokenizer.perl
INPUT_FROM_SGM=$MOSES/scripts/ems/support/input-from-sgm.perl

# fastBPE
FASTBPE_DIR=$TOOLS_PATH/fastBPE
FASTBPE=$TOOLS_PATH/fastBPE/fast

# Sennrich's WMT16 scripts for Romanian preprocessing
WMT16_SCRIPTS=$TOOLS_PATH/wmt16-scripts
NORMALIZE_ROMANIAN=$WMT16_SCRIPTS/preprocess/normalise-romanian.py
REMOVE_DIACRITICS=$WMT16_SCRIPTS/preprocess/remove-diacritics.py

# install tools
./install-tools.sh

# valid / test file raw data
unset PARA_SRC_VALID PARA_TGT_VALID PARA_SRC_TEST PARA_TGT_TEST
if [ "$SRC" == "en" -a "$TGT" == "fr" ]; then
  PARA_SRC_VALID=$PARA_PATH/dev/newstest2013-ref.en
  PARA_TGT_VALID=$PARA_PATH/dev/newstest2013-ref.fr
  PARA_SRC_TEST=$PARA_PATH/dev/newstest2014-fren-ref.en
  PARA_TGT_TEST=$PARA_PATH/dev/newstest2014-fren-ref.fr
fi
if [ "$SRC" == "en" -a "$TGT" == "de" ]; then
  PARA_SRC_VALID=$PARA_PATH/dev/newstest2013-ref.en
  PARA_TGT_VALID=$PARA_PATH/dev/newstest2013-ref.de
  PARA_SRC_TEST=$PARA_PATH/dev/newstest2016-deen-ref.en
  PARA_TGT_TEST=$PARA_PATH/dev/newstest2016-ende-ref.de
fi
if [ "$SRC" == "en" -a "$TGT" == "ro" ]; then
  PARA_SRC_VALID=$PARA_PATH/dev/newsdev2016-roen-ref.en
  PARA_TGT_VALID=$PARA_PATH/dev/newsdev2016-enro-ref.ro
  PARA_SRC_TEST=$PARA_PATH/dev/newstest2016-roen-ref.en
  PARA_TGT_TEST=$PARA_PATH/dev/newstest2016-enro-ref.ro
fi
if [ "$SRC" == "en" -a "$TGT" == "ru" ]; then
  PARA_SRC_VALID=$PARA_PATH/dev/newstest2017-ruen-ref.en
  PARA_TGT_VALID=$PARA_PATH/dev/newstest2017-enru-ref.ru
  PARA_SRC_TEST=$PARA_PATH/dev/newstest2018-ruen-ref.en
  PARA_TGT_TEST=$PARA_PATH/dev/newstest2018-enru-ref.ru
fi
if [ "$SRC" == "en" -a "$TGT" == "kk" ]; then
  PARA_SRC_VALID=$PARA_PATH/dev/newsdev2019-kken-ref.en
  PARA_TGT_VALID=$PARA_PATH/dev/newsdev2019-enkk-ref.kk
  PARA_SRC_TEST=$PARA_PATH/dev/newstest2019-kken-ref.en
  PARA_TGT_TEST=$PARA_PATH/dev/newstest2019-kken-src.kk
fi
if [ "$SRC" == "en" -a "$TGT" == "gu" ]; then
  PARA_SRC_VALID=$PARA_PATH/dev/newsdev2019-guen-ref.en
  PARA_TGT_VALID=$PARA_PATH/dev/newsdev2019-engu-ref.gu
  PARA_SRC_TEST=$PARA_PATH/dev/newstest2019-guen-ref.en
  PARA_TGT_TEST=$PARA_PATH/dev/newstest2019-guen-src.gu
fi
if [ "$SRC" == "en" -a "$TGT" == "zh" ]; then
  PARA_SRC_VALID=$PARA_PATH/dev/newstest2018-zhen-ref.en
  PARA_TGT_VALID=$PARA_PATH/dev/newstest2018-enzh-ref.zh
  PARA_SRC_TEST=$PARA_PATH/dev/newstest2019-zhen-ref.en
  PARA_TGT_TEST=$PARA_PATH/dev/newstest2019-zhen-src.zh
fi

# here I will add codes for downloading more datasets of different languages further

cd $MONO_PATH

if [ "$SRC" == "de" -o "$TGT" == "de" ]; then
  echo "Downloading German monolingual data ..."
  mkdir -p $MONO_PATH/de
  cd $MONO_PATH/de
  wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2007.de.shuffled.gz
  wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2008.de.shuffled.gz
  wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2009.de.shuffled.gz
  wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2010.de.shuffled.gz
  wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2011.de.shuffled.gz
  wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2012.de.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2013.de.shuffled.gz
  # wget -c http://www.statmt.org/wmt15/training-monolingual-news-crawl-v2/news.2014.de.shuffled.v2.gz
  # wget -c http://data.statmt.org/wmt16/translation-task/news.2015.de.shuffled.gz
  # wget -c http://data.statmt.org/wmt17/translation-task/news.2016.de.shuffled.gz
  # wget -c http://data.statmt.org/wmt18/translation-task/news.2017.de.shuffled.deduped.gz
fi

if [ "$SRC" == "en" -o "$TGT" == "en" ]; then
  echo "Downloading English monolingual data ..."
  mkdir -p $MONO_PATH/en
  cd $MONO_PATH/en
  wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2007.en.shuffled.gz
  wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2008.en.shuffled.gz
  wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2009.en.shuffled.gz
  wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2010.en.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2011.en.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2012.en.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2013.en.shuffled.gz
  # wget -c http://www.statmt.org/wmt15/training-monolingual-news-crawl-v2/news.2014.en.shuffled.v2.gz
  # wget -c http://data.statmt.org/wmt16/translation-task/news.2015.en.shuffled.gz
  # wget -c http://data.statmt.org/wmt17/translation-task/news.2016.en.shuffled.gz
  # wget -c http://data.statmt.org/wmt18/translation-task/news.2017.en.shuffled.deduped.gz
fi

if [ "$SRC" == "fr" -o "$TGT" == "fr" ]; then
  echo "Downloading French monolingual data ..."
  mkdir -p $MONO_PATH/fr
  cd $MONO_PATH/fr
  wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2007.fr.shuffled.gz
  wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2008.fr.shuffled.gz
  wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2009.fr.shuffled.gz
  wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2010.fr.shuffled.gz
  wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2011.fr.shuffled.gz
  wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2012.fr.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2013.fr.shuffled.gz
  # wget -c http://www.statmt.org/wmt15/training-monolingual-news-crawl-v2/news.2014.fr.shuffled.v2.gz
  # wget -c http://data.statmt.org/wmt17/translation-task/news.2015.fr.shuffled.gz
  # wget -c http://data.statmt.org/wmt17/translation-task/news.2016.fr.shuffled.gz
  # wget -c http://data.statmt.org/wmt17/translation-task/news.2017.fr.shuffled.gz
fi

if [ "$SRC" == "ru" -o "$TGT" == "ru" ]; then
  echo "Downloading Russian monolingual data ..."
  mkdir -p $MONO_PATH/ru
  cd $MONO_PATH/ru
  wget -c https://data.statmt.org/news-crawl/ru/news.2008.ru.shuffled.deduped.gz
  wget -c https://data.statmt.org/news-crawl/ru/news.2009.ru.shuffled.deduped.gz
  wget -c https://data.statmt.org/news-crawl/ru/news.2010.ru.shuffled.deduped.gz
  wget -c https://data.statmt.org/news-crawl/ru/news.2011.ru.shuffled.deduped.gz
  wget -c https://data.statmt.org/news-crawl/ru/news.2012.ru.shuffled.deduped.gz
  wget -c https://data.statmt.org/news-crawl/ru/news.2013.ru.shuffled.deduped.gz
  wget -c https://data.statmt.org/news-crawl/ru/news.2014.ru.shuffled.deduped.gz
  # wget -c https://data.statmt.org/news-crawl/ru/news.2015.ru.shuffled.deduped.gz
  # wget -c https://data.statmt.org/news-crawl/ru/news.2016.ru.shuffled.deduped.gz
  # wget -c https://data.statmt.org/news-crawl/ru/news.2017.ru.shuffled.deduped.gz
  # wget -c https://data.statmt.org/news-crawl/ru/news.2018.ru.shuffled.deduped.gz
fi

if [ "$SRC" == "kk" -o "$TGT" == "kk" ]; then
  echo "Downloading Kazakh monolingual data ..."
  mkdir -p $MONO_PATH/kk
  cd $MONO_PATH/kk
  wget -c https://data.statmt.org/news-crawl/kk/news.2018.kk.shuffled.deduped.gz
  wget -c https://data.statmt.org/news-crawl/kk/news.2019.kk.shuffled.deduped.gz
  wget -c https://data.statmt.org/news-crawl/kk/news.2020.kk.shuffled.deduped.gz
  wget -c https://data.statmt.org/news-crawl/kk/news.2021.kk.shuffled.deduped.gz
fi

if [ "$SRC" == "gu" -o "$TGT" == "gu" ]; then
  echo "Downloading Gujarati monolingual data ..."
  mkdir -p $MONO_PATH/gu
  cd $MONO_PATH/gu
  wget -c https://data.statmt.org/news-crawl/gu/news.2018.gu.shuffled.deduped.gz
  wget -c https://data.statmt.org/news-crawl/gu/news.2019.gu.shuffled.deduped.gz
  wget -c https://data.statmt.org/news-crawl/gu/news.2020.gu.shuffled.deduped.gz
  wget -c https://data.statmt.org/news-crawl/gu/news.2021.gu.shuffled.deduped.gz
fi

if [ "$SRC" == "ro" -o "$TGT" == "ro" ]; then
  echo "Downloading Romanian monolingual data ..."
  mkdir -p $MONO_PATH/ro
  cd $MONO_PATH/ro
  wget -c http://data.statmt.org/wmt16/translation-task/news.2015.ro.shuffled.gz
fi

if [ "$SRC" == "zh" -o "$TGT" == "zh" ]; then
  echo "Downloading Chinese monolingual data ..."
  mkdir -p $MONO_PATH/zh
  cd $MONO_PATH/zh
  wget -c https://data.statmt.org/news-crawl/zh/news.2008.zh.shuffled.deduped.gz
  wget -c https://data.statmt.org/news-crawl/zh/news.2010.zh.shuffled.deduped.gz
  wget -c https://data.statmt.org/news-crawl/zh/news.2011.zh.shuffled.deduped.gz
  wget -c https://data.statmt.org/news-crawl/zh/news.2012.zh.shuffled.deduped.gz
  wget -c https://data.statmt.org/news-crawl/zh/news.2013.zh.shuffled.deduped.gz
  wget -c https://data.statmt.org/news-crawl/zh/news.2014.zh.shuffled.deduped.gz
  wget -c https://data.statmt.org/news-crawl/zh/news.2015.zh.shuffled.deduped.gz
  wget -c https://data.statmt.org/news-crawl/zh/news.2016.zh.shuffled.deduped.gz
  wget -c https://data.statmt.org/news-crawl/zh/news.2017.zh.shuffled.deduped.gz
  wget -c https://data.statmt.org/news-crawl/zh/news.2018.zh.shuffled.deduped.gz
  wget -c https://data.statmt.org/news-crawl/zh/news.2019.zh.shuffled.deduped.gz
  wget -c https://data.statmt.org/news-crawl/zh/news.2020.zh.shuffled.deduped.gz
  wget -c https://data.statmt.org/news-crawl/zh/news.2021.zh.shuffled.deduped.gz
fi

cd $MONO_PATH

# decompress monolingual data
for FILENAME in $SRC/news*gz $TGT/news*gz; do
  OUTPUT="${FILENAME::-3}"
  if [ ! -f "$OUTPUT" ]; then
    echo "Decompressing $FILENAME..."
    gunzip -k $FILENAME
  else
    echo "$OUTPUT already decompressed."
  fi
done

# concatenate monolingual data files
if ! [[ -f "$SRC_RAW" ]]; then
  echo "Concatenating $SRC monolingual data..."
  cat $(ls $SRC/news*$SRC* | grep -v gz) | head -n $N_MONO > $SRC_RAW
fi
if ! [[ -f "$TGT_RAW" ]]; then
  echo "Concatenating $TGT monolingual data..."
  cat $(ls $TGT/news*$TGT* | grep -v gz) | head -n $N_MONO > $TGT_RAW
fi
echo "$SRC monolingual data concatenated in: $SRC_RAW"
echo "$TGT monolingual data concatenated in: $TGT_RAW"


#
# Download parallel data (for evaluation only)
#

cd $PARA_PATH

echo "Downloading parallel data..."
wget -c http://data.statmt.org/wmt20/translation-task/dev.tgz

echo "Extracting parallel data..."
tar -xzf dev.tgz

# check valid and test files are here
if ! [[ -f "$PARA_SRC_VALID.sgm" ]]; then echo "$PARA_SRC_VALID.sgm is not found!"; exit; fi
if ! [[ -f "$PARA_TGT_VALID.sgm" ]]; then echo "$PARA_TGT_VALID.sgm is not found!"; exit; fi
if ! [[ -f "$PARA_SRC_TEST.sgm" ]];  then echo "$PARA_SRC_TEST.sgm is not found!";  exit; fi
if ! [[ -f "$PARA_TGT_TEST.sgm" ]];  then echo "$PARA_TGT_TEST.sgm is not found!";  exit; fi

echo " valid and test data..."
eval "$INPUT_FROM_SGM < $PARA_SRC_VALID.sgm > $PARA_SRC_VALID_RAW"
eval "$INPUT_FROM_SGM < $PARA_TGT_VALID.sgm > $PARA_TGT_VALID_RAW"
eval "$INPUT_FROM_SGM < $PARA_SRC_TEST.sgm > $PARA_SRC_TEST_RAW"
eval "$INPUT_FROM_SGM < $PARA_TGT_TEST.sgm > $PARA_TGT_TEST_RAW"

#
# Summary
#
echo ""
echo "===== Data summary"
echo "Monolingual raw training data:"
echo "    $SRC: $SRC_RAW"
echo "    $TGT: $TGT_RAW"
echo "Parallel raw validation data:"
echo "    $SRC: $PARA_SRC_VALID_RAW"
echo "    $TGT: $PARA_TGT_VALID_RAW"
echo "Parallel raw test data:"
echo "    $SRC: $PARA_SRC_TEST_RAW"
echo "    $TGT: $PARA_TGT_TEST_RAW"
echo ""
