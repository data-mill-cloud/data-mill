# variables to mandatorily return in output
VARS=(LOCATION ACTION)

OPTIONS=":drliuc:"

while getopts $OPTIONS opt; do
  case $opt in
    d)
      echo "-d: debug mode enabled, spawning environment"
      ACTION="debug"
      break
      ;;
    r)
      echo "-r: running to remote cluster"
      LOCATION="remote"
      ;;
    l)
      echo "-l: running local cluster"
      LOCATION="local"
      ;;
    i)
      echo "-i: installing infrastructure"
      ACTION="install"
      ;;
    u)
      echo "-u: uninstalling infrastructure"
      ACTION="delete"
      ;;
    c)
      echo "-c: overwriting default config.yaml with -$OPTARG" >&2
      CONFIG=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# print usage if any of the variables is not set
if [ "$ACTION" != "debug" ]; then
  for var in "${VARS[@]}"
  do
    if [ -z ${!var} ]; then
      echo "Usage: $0 [debug-mode] [params] [options]"
      echo "  debug mode:"
      echo "    DEBUG: -d"
      echo "  params:"
      echo "    LOCATION: -l (local), -r (remote)"
      echo "    ACTION: -i (install), -u (uninstall)"
      echo "  options:"
      echo "    CONFIG: -c config_file_name.yaml"
      exit 1
    fi
  done
fi
