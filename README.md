# XLM-Language-Discriminator

Based on [XLM](https://github.com/facebookresearch/XLM) codebase.

### Prerequisites

#### Dependencies
(the same as the environment as the project [Improving the Lexical Ability of Pretrained Language Models for Unsupervised Neural Machine Translation](https://github.com/alexandra-chron/lexical_xlm_relm))

- Python 3.6.9
- [NumPy](http://www.numpy.org/) (tested on version 1.15.4)
- [PyTorch](http://pytorch.org/) (tested on version 1.2.0 and 1.4.0)
- [Apex](https://github.com/NVIDIA/apex#quick-start) (for fp16 training)
- [jieba](https://github.com/fxsjy/jieba) (A tokenizer for chinese, simply pip install jieba)

#### Download data

Download the monolinual data and valid/test sets for evaluation of a language pair (en-xx), taking en-fr and en-de for example:
```
./download_unmt_data.sh --src en --tgt fr
./download_unmt_data.sh --src en --tgt de
```
Then the data will automatically be downloaded (also renamed as ,e.g., train_raw.en/valid_raw.en/test_raw.en) into /data/mono and /data/para.

More languages will be added ...


#### Preprocessing

Preprocess the data of a language pair (en-xx), taking en-fr and en-de for example:
```
./process_unmt_data.sh --src en --tgt fr
./process_unmt_data.sh --src en --tgt de
```
In addtion, if pretrained models are used, an exactly identical vocabulary should be leveraged. To use given BPE codes and vocabulary, simply download them and run codes like the following:
```
wget https://dl.fbaipublicfiles.com/XLM/codes_enfr
wget https://dl.fbaipublicfiles.com/XLM/vocab_enfr
./process_unmt_data.sh --src en --tgt fr --reload_codes codes_enfr --reload_vocab vocab_enfr
```

The preprocessed data will be in ./data/processed/en-xx.

### Pretrain a language model (with MLM)

To train with multiple GPUs use:
```
export NGPU=8; python -m torch.distributed.launch --nproc_per_node=$NGPU train.py
```

To train with multiple GPUs and half precision use:
```
export NGPU=8; python -m torch.distributed.launch --nproc_per_node=$NGPU train.py --fp16 True --amp 1 
```

The following script will pretrain a model with the MLM objective for English and French:
```
python train.py                               \
--exp_name enfr_mlm                           \
--dump_path ./dumped                          \
--data_path ./data/processed/en-fr/           \ 
--lgs 'en-fr'                                 \
--mlm_steps 'en,fr'                           \
--emb_dim 1024                                \
--n_layers 6                                  \
--n_heads 8                                   \
--dropout 0.1                                 \
--attention_dropout 0.1                       \  
--gelu_activation true                        \
--batch_size 32                               \
--bptt 256                                    \
--optimizer 'adam,lr=0.0001'                  \ 
--epoch_size 200000                           \
--validation_metrics _valid_mlm_ppl           \ 
--stopping_criterion '_valid_mlm_ppl,10'      
```
### Fine-tune an UNMT model with DAE, BT and language discriminator loss

The following script will fine-tune an UNMT model **with language discriminator loss**:
```
python train.py                                               \
--exp_name unmt_en_fr_pretrained_lang_dis                     \
--dump_path ./dumped/                                         \
--reload_model 'mlm_enfr_1024.pth,mlm_enfr_1024.pth'          \
--data_path ./data/processed/en-fr/                           \
--lgs 'en-fr'                                                 \
--ae_steps 'en,fr'                                            \
--bt_steps 'en-fr-en,fr-en-fr'                                \
--word_shuffle 3                                              \
--word_dropout 0.1                                            \
--word_blank 0.1                                              \
--lambda_ae '0:1,100000:0.1,300000:0'                         \
--encoder_only false                                          \
--emb_dim 1024                                                \
--n_layers 6                                                  \
--n_heads 8                                                   \
--dropout 0.1                                                 \
--attention_dropout 0.1                                       \
--gelu_activation true                                        \
--tokens_per_batch 2000                                       \
--batch_size 32                                               \
--bptt 256                                                    \
--optimizer adam_inverse_sqrt,beta1=0.9,beta2=0.98,lr=0.0001  \
--epoch_size 200000                                           \
--eval_bleu true                                              \
--stopping_criterion 'valid_en-fr_mt_bleu,10'                 \
--validation_metrics 'valid_en-fr_mt_bleu'                    \
--max_epoch 100                                               \
--use_language_discriminator true                             \
--language_discriminator_loss_weight 1.0                      \
--n_layer_dis 2
```


The following script will fine-tune an UNMT model **without language discriminator loss**:
```
python train.py                                               \
--exp_name unmt_en_fr_pretrained                              \
--dump_path ./dumped/                                         \
--reload_model 'mlm_enfr_1024.pth,mlm_enfr_1024.pth'          \
--data_path ./data/processed/en-fr/                           \
--lgs 'en-fr'                                                 \
--ae_steps 'en,fr'                                            \
--bt_steps 'en-fr-en,fr-en-fr'                                \
--word_shuffle 3                                              \
--word_dropout 0.1                                            \
--word_blank 0.1                                              \
--lambda_ae '0:1,100000:0.1,300000:0'                         \
--encoder_only false                                          \
--emb_dim 1024                                                \
--n_layers 6                                                  \
--n_heads 8                                                   \
--dropout 0.1                                                 \
--attention_dropout 0.1                                       \
--gelu_activation true                                        \
--tokens_per_batch 2000                                       \
--batch_size 32                                               \
--bptt 256                                                    \
--optimizer adam_inverse_sqrt,beta1=0.9,beta2=0.98,lr=0.0001  \
--epoch_size 200000                                           \
--eval_bleu true                                              \
--stopping_criterion 'valid_en-fr_mt_bleu,10'                 \
--validation_metrics 'valid_en-fr_mt_bleu'                    \
--max_epoch 100                                               
```

### References

Please cite [[1]](https://aclanthology.org/2023.iwslt-1.48/) if you found the resources in this repository useful.

```
@inproceedings{liu-etal-2023-copying,
    title = "On the Copying Problem of Unsupervised {NMT}: A Training Schedule with a Language Discriminator Loss",
    author = {Liu, Yihong  and
      Chronopoulou, Alexandra  and
      Sch{\"u}tze, Hinrich  and
      Fraser, Alexander},
    booktitle = "Proceedings of the 20th International Conference on Spoken Language Translation (IWSLT 2023)",
    month = jul,
    year = "2023",
    address = "Toronto, Canada (in-person and online)",
    publisher = "Association for Computational Linguistics",
    url = "https://aclanthology.org/2023.iwslt-1.48",
    doi = "10.18653/v1/2023.iwslt-1.48",
    pages = "491--502"
}
```
