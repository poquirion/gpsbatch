
usage () {

cat  << EOF
  $0   [-c <command>] [-n <N hosts>] [-t <wall time>]  <parameters file>
  <N hosts>
    How many Host to run code, all the cores are taken DEFAULT; 1
  <parameter file>
    The parameter file to feed the tool
  -c <command>
   The command to run on the parameter file DEFAULT: echo
  -t <wall time>
   Slurm walltime default: 03:00:00

EOF
}


COMMAND=echo
WALLTIME=3:00:00
N_HOSTS=1

while getopts ":c:t:n:h" opt; do
  case $opt in
    c)
      COMMAND=${OPTARG}
      ;;
    t)
      WALLTIME=${OPTARG}
      ;;
    n)
      N_HOSTS=${OPTARG}
      ;;
    h)
      usage
      exit 0
      ;;
    \?)
      usage
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      usage
      exit 1
      ;;
  esac
done



shift $((OPTIND-1))




if [ $# -ne 1 ]; then
  usage
  exit 1
fi


export parameters_file=$2

JOB_NAME=$COMMAND


sbatch_file=$(mktemp /tmp/gnu_parallel_XXXXXX.sh)

  cat << EOF >$sbatch_file
#!/usr/bin/env bash

scontrol show hostname \${SLURM_JOB_NODELIST} > node_list_\${SLURM_JOB_ID}

parallel --joblog ./job.log  --resume-failed  --jobs \${SLURM_CPUS_ON_NODE} --sshloginfile \
 node_list_\${SLURM_JOB_ID}  --workdir $PWD --env _  "$COMMAND"  < $parameters_file
EOF

chmod 755 $sbatch_file

sbatch -A $RAP_ID  --time $WALLTIME --mem=4775  --ntasks-per-node=40 --nodes=$N_HOSTS \
     --job-name=$JOBNAME  --output=$JOBNAME.slurm-%j.out  $sbatch_file


done
