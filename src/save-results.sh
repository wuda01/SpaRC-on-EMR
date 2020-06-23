#!/bin/bash
set -x -e

while [ $# -gt 0 ]; do
    case "$1" in
    --save-results)
      shift
      SAVE_RESULTS=$1
      ;;
    -*)
      # do not exit out, just note failure
      error_msg "unrecognized option: $1"
      ;;
    *)
      break;
      ;;
    esac
    shift
done

#hadoop fs -getmerge seqaddid_output seqaddid
#hadoop fs -getmerge minimizer minimizer
#hadoop fs -getmerge global_minimizer global_minimizer
#hadoop fs -getmerge graphgen2_output graphgen2
#hadoop fs -getmerge graphlpa3_output graphlpa3
#hadoop fs -getmerge globalcluster_output globalcluster
#hadoop fs -getmerge graphlpa3_global_output graphlpa3_global
hadoop fs -getmerge ccaddseq_output ccaddseq
hadoop fs -getmerge metric_output metric


#aws s3 cp seqaddid $SAVE_RESULTS/seqaddid
#aws s3 cp minimizer $SAVE_RESULTS/minimizer
#aws s3 cp global_minimizer $SAVE_RESULTS/global_minimizer
#aws s3 cp graphgen2 $SAVE_RESULTS/graphgen2
#aws s3 cp graphlpa3 $SAVE_RESULTS/graphlpa3
#aws s3 cp globalcluster $SAVE_RESULTS/globalcluster
#aws s3 cp graphlpa3_global $SAVE_RESULTS/graphlpa3_global
aws s3 cp ccaddseq $SAVE_RESULTS/ccaddseq
aws s3 cp metric $SAVE_RESULTS/metric
