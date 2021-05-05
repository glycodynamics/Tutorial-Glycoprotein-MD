# 2011-01, Sushil Mishra, NCBR, Masaryk University, Czech Republic
# sushil@chemi.muni.cz
# Desc: General function set for MEscripts
#
#


################################################################################
# Init functions
################################################################################

Mes_Test_Bash_Version() {
  # description: test the current shell version
  # arguments: none
  # return values: 0 - bash ver. 3 and higher
  #+               1 - bash ver. 2 and lower
  local fn=Mes_Test_Bash_Version    # function name

  # local variables
  local bv    # main bash version number
  local a    # array


  Mes_Msg 2 "Testing the shell."

  Mes_Recognise_Stringently $SHELL /usr/bin/bash "The currently running shell is not bash."

  bv=`bash --version | sed -n '1{s/[^0-9]//g;s/./&a/;s/a[0-9]*$//;p}'`
  [ -z "$bv" ] && bv=0

  if [ $bv -lt 3 ]; then
    Mes_Errr "Bash check failed, bash version: $bv."
  fi


  Mes_Msg 2 "Testing bash for arrays."

  # test the array support of the current bash shell
  a[0]="test" || Mes_Errr "Arrays are not supported in this version of bash shell."

  return 0
}




Mes_Test_Environment() {
  # description: test the MES_PREFIX installation path/prefix and probe the hidden check-file
  # arguments: none
  # return values: 0 if MEscripts are installed in the location
  #+               1 otherwise
  local fn=Mes_Test_Environment    # function name

  # local variables
  local code=0    # return value

  Mes_Msg 2 "Verifing the MES_PREFIX variable."

  # checking the MES_PREFIX variable
  if [ -z "$MES_PREFIX" ]; then
    Mes_Errr "The MES_PREFIX shell variable is not defined, check the installation instructions."
  else
    Mes_Msg 2 "Probing the hidden checkfile:"
    if [ `grep -c "mescripts" $MES_PREFIX/lib/mescripts/.checkfile 2> /dev/null` -eq 1 ]; then
      Mes_Msg 2 "  O.K."
    else
      Msg_Errr "Your MES installation in $MES_PREFIX is corrupted."
    fi
  fi

  Mes_Msg 1 "The MES_PREFIX variable is: $MES_PREFIX."
}




Mes_Test_Software() {
  # description: test if the specified commands are in the search PATH
  # arguments: one and more - the commands
  # return values: 1 - one of the commands is not in the PATH
  #+               0 otherwise
  local fn=Mes_Test_Software    # function name

  # argument checks
  [ $# -eq 0 ] && Mes_Errr "No commands to test." 

  # local variables
  local arg    # argument
  local test    # command/s to test
  local com    # commad

  for arg do
    if [[ $arg =~ _MODULE_ ]]; then
      # get the module name
      eval arg=\"\$$arg\"

      # a simple database of commands for selected modules
      case ${arg%%:*} in
        amber)
          test="sander|sander.MPI|_sander.MPI|pmemd|pmemd.MPI|_pmemd.MPI"
          ;;
        gaussian)
          test="g09|g03|g98"
          ;;
        cats)
          test="gauss-aw-gen|topinfo"
          ;;
        autodock-vina)
          test="vina"
          ;;
        *)
          test="${arg%%:*}"
          ;;
      esac
    else
      test=$arg
    fi
    
    for com in ${test//|/ }; do
      Mes_Msg 2 "Testing '$com'."

      # test
      if ! type $com &> /dev/null; then

        if [ `echo $test | grep -c "|"` -eq 1 ]; then
          # catch the last possible command
          if [ `echo $test | grep -c "|$com\$"` -eq 1 ]; then
            Mes_Errr "None of '$test' is not available. Install the software or call an appropriate module."
          fi

        else
          Mes_Errr "'$test' is not available. Install the software or call an appropriate module."
        fi

      else
        break
      fi

    done
  done

  return 0
}




################################################################################
# MES messaging functions
################################################################################


Mes_Msg() {
  # description: ouput a message at the current verbosity level
  #+             verb. 0 silent
  #+             verb. 1 some messages
  #+             verb. 2 all messages
  # arguments: verbosity message
  # return values: 0 always
  # function name is not defined but reused in the higher verbosity mode

  # argument checks
  #Mes_Recognise_Stringently $1 0-9
  # -- this one is an unnecessary polution

  # local variables
  local msg=""    # message to report
  local v=$1    # verb. level
  shift

  #
  # compare the requested verbosity level with the level of the message
  #
  if [ ${MES_VERBOSITY:=0} -ge ${v%e} ]; then
    if [ ${v%e} -le 1 ]; then
      msg="$@"
    else
      if [ -n "$fn" ]; then
        msg="$fn: $@"
      else
        msg="$0: $@"
      fi
    fi

    if [[ $v =~ e ]]; then
      echo "$msg" 1>&2
    else
      echo "$msg"
    fi
  fi

  # logging? MES_LOG_FILE
  return 0
}




Mes_Msg_Gag() {
  # description: set verbosity level to 0 temporarily
  #+             only the fuction which set the gag may actually release it
  # arguments: --on|--off
  # return values: 0 always
  # function name is not defined but reused

  # argument checks
  [ $# -eq 0 ] && Mes_Errr "No argument."

  # global variables
  #MES_VERBOSITY_GAG    # store the previous verbosity level

  case "$1" in
    --on)
      # switch on only if unset
      if [ -z "$MES_VERBOSITY_GAG" ]; then
        if [ -n "$fn" ]; then
          MES_VERBOSITY_GAG=( ${MES_VERBOSITY:-0} $fn )
        else
          MES_VERBOSITY_GAG=( ${MES_VERBOSITY:-0} "$0" )
        fi
        MES_VERBOSITY=0
      fi
      ;;
    --off)
      if [ -n "$MES_VERBOSITY_GAG" ] && \
         { { [ -n "$fn" ] && [ "${MES_VERBOSITY_GAG[1]}" = "$fn" ]; } || \
           { [ -z "$fn" ] && [ "${MES_VERBOSITY_GAG[1]}" = "$0" ]; }; }; then
          MES_VERBOSITY=$MES_VERBOSITY_GAG
          MES_VERBOSITY_GAG=()
      fi
      ;;
  esac

  return 0
}




Mes_Warnng() {
  # description: reports a warning message
  # arguments: warning message
  # return values: 0 always
  # function name is not defined but reused

  # argument checks
  if [ $# -lt 1 ]; then
    echo "Mes_Warnng WARNNG: No message to report." 1>&2
  fi

  if [ -n "$fn" ]; then
    echo "$fn: WARNNG: $@" 1>&2
  else
    echo "WARNNG: $@" 1>&2
  fi
}




Mes_Errr() {
  # description: reports an error message and exits
  # arguments: error message
  # return values: $code if exists
  #+               1 otherwise
  # function name is not defined but reused

  # argument checks
  if [ $# -lt 1 ]; then
    echo "Mes_Errr ERRR: No message to report." 1>&2
  fi

  # local variables
  date=false    # include date and time optionally

  if [ "$1" = --date ]; then
    date=true
    shift
  fi

  if [ -n "$fn" ]; then
    echo "$fn: ERRR: $@" 1>&2
    $date && echo "$fn: ERRR: encountered on `date -R`." 1>&2
  else
    echo "'$0' ERRR: $@" 1>&2
    $date && echo "'$0' ERRR: encountered on `date -R`." 1>&2
  fi

  # exit finally

  # the global return value
  if [ -n "$mes_retval" ] && [ $mes_retval -gt 0 ]; then
    exit $mes_retval

  # local exit code
  elif [ -n "$code" ] && [ $code -gt 0 ]; then
    exit $code

  else
    exit 1
  fi
}




################################################################################
# Parsing command line input
################################################################################


Mes_Parse_Cmdline_Arguments() {
  # description: parse command line arguments and store those not recognised
  #+             into specific variables. Basically there are two modes
  #+             of operation:
  #+               changes the value of a variable - options without arguments
  #+                 cmd line syntax: --option
  #+                 direction syntax: --option->VARIABLE=value
  #+               the data following the option are stored into a variable - options with arguments
  #+                 cmd line syntax: --option argument   OR
  #+                                  --option=argument
  #+                 direction syntax: --option->VARIABLE.
  #+             The directives must have spaces or new lines between the
  #+             intividual entries.
  # arguments: 1st - directives for parsing
  #+           others - the actual command line arguments
  # return values: 1 - error in the directives
  #+               0 otherwise
  # note: the function call must use "$@" to allow for arguments with spaces
  # note: options by themselves must not contain `=' signs
  # function name is not defined but reused in the higher verbosity mode
  #local fn=Mes_Parse_Cmdline_Arguments    # function name

  # argument checks
  [ $# -eq 0 ] && Mes_Errr "No arguments." 

  #### initialise a global var
  #
  mes_input=()    # the default array used for reading the non-option data

  # local variables
  local mes_shift_args    # for the parse options function


  Mes_Msg 2 "Parsing cmdln options."

  Mes_Parse_Cmdline_Options "$@"
  shift
  shift $mes_shift_args


  Mes_Msg 2 "Parsing non-option arguments."

  #### DO NOT use the 'mes_input' array, it is use internaly by many functions
  #+   working with stdin and it is not possible to Mes_ManVar
  #+   this variable, value removal is an issue
  #
  Mes_Read  --not-edacious  --name  mes_arguments  -- "$@"


  return 0
}




Mes_Parse_Cmdline_Options() {
  # description: parse only command line options, store them in variables
  #+             and stop at the first argument which is not an option or '--'
  #+             which denotes the end of options. Basically there are two
  #+             modes of operation:
  #+               changes the value of a variable - options without arguments
  #+                 cmd line syntax: --option
  #+                 direction syntax: --option->VARIABLE=value
  #+               the data following the option are stored into a variable - options with arguments
  #+                 cmd line syntax: --option argument   OR
  #+                                  --option=argument
  #+                 direction syntax: --option->VARIABLE.
  #+             Options which have not been recognised are regarded as the
  #+             first non-option argument.
  #+             Individual directives must have spaces or new lines between the
  #+             intividual entries.
  # arguments: 1st - directives for parsing
  #+           others - the actual command line arguments
  # return values: 1 - error in the directives
  #+               0 otherwise
  # note: the function call must use "$@" to allow for arguments with spaces
  # note: options by themselves must not contain `=' signs
  # note: a shift command `shift \$mes_shift_args' has to be executed after
  #+      this function is called
  # function name is not defined but reused in the higher verbosity mode
  #local fn=Mes_Parse_Cmdline_Options    # function name

  # argument checks
  [ $# -eq 0 ] && Mes_Errr "No arguments." 

  # global vars
  mes_shift_args=0    # the number of arguments to shift in the script/function calling this function

  # local variables
  local dirs    # parsing directives
  local hit    # the currently selected option/variable

  Mes_Msg 2 "Storing the parsing directives."
  dirs="`printf "%s\n" "$1" | \
           sed -n '1h; 2,$H; ${ x; s/\n/ /g; s/ \+/ /g; s/->/ /g; p }'`"
  shift

  # check if the number of directives is even
  [ $(( `echo $dirs | wc -w` % 2 )) -eq 1 ] && Mes_Errr "Odd number of directives."

  until [ $# -eq 0 ]; do
    Mes_Msg 2 "Trying to match the current argument: $1"

    # process only strings which start with a hyphen
    if [[ $1 =~ ^- ]]; then
      #
      # I'm not sure if it is good to have it here.
      #
      # a single hyphen will be a request to read stdin and not an unknown option
      if [ "$1" = - ]; then
        hit=stdin
        # leave the hyphen in the non-option arguments
        ###((++mes_shift_args))
      #############################################

      elif [ "$1" = -- ]; then
        hit=end_of_options
        # remove the end of options
        ((++mes_shift_args))

      else
        # strip any possible option argument attached by `=' to the current parameter '$1'
        hit="`printf "%s %s\n" $dirs | grep "^${1%%=*} " | head -n1`"

        # increase the shift number for non-zero hits
        [ -n "$hit" ] && ((++mes_shift_args))
      fi

    else
      hit=""
    fi


    case "$hit" in

      # 1st mode - options without arguments
      -*" "*=*)
        Mes_Msg 2 "  -- an option without argument recognised"

        # make an exception for gaged verbosity
        if [[ ${hit#* } =~ MES_VERBOSITY=[0-9] ]] && [ -n "$MES_VERBOSITY_GAG" ]; then
          eval MES_VERBOSITY_GAG[0]=\""${hit#*=}"\"
        else
          eval ${hit#* }
        fi
        ;;

      # 2nd mode - options with arguments
      -*)
        if [[ $1 =~ = ]]; then
          Mes_Msg 2 "  -- an option with argument recognised, '--option=argument' syntax"

          # make an exception for gaged verbosity
          if [[ ${hit#* } =~ MES_VERBOSITY$ ]] && [ -n "$MES_VERBOSITY_GAG" ]; then
            eval MES_VERBOSITY_GAG[0]=\""${1#*=}"\"
          else
            # get everything following the `='
            eval ${hit#* }=\""${1#*=}"\"
          fi

        else
          Mes_Msg 2 "  -- an option with argument recognised, '--option argument' syntax"

          # add one more shift
          ((++mes_shift_args))

          # rid us of the option, move to the argument
          shift

          # make an exception for gaged verbosity
          if [[ ${hit#* } =~ MES_VERBOSITY$ ]] && [ -n "$MES_VERBOSITY_GAG" ]; then
            eval MES_VERBOSITY_GAG[0]=\""$1"\"
          else
            eval ${hit#* }=\""$1"\"
          fi
        fi
        ;;

      end_of_options)
        Mes_Msg 2 "  -- the end of options"

        # break from the until cycle
        break
        ;;

      stdin)
        Mes_Msg 2 "  -- single hyphen, stdin read"

        # break from the until cycle
        break
        ;;

      # there was no hit
      *)
        Mes_Msg 2 "  -- an argument/option not recognised"

        case "$1" in
          --*)
            Mes_Errr "Unknown long option: $1"
            ;;
          -*)
            Mes_Errr "Unknown short option: $1"
            ;;
          *)
            Mes_Msg 2 "  -- the first non-option argument"

            # break from the until cycle
            break
            ;;
        esac
        ;;
    esac
    shift
  done

  return 0
}




################################################################################
# String manipulation
################################################################################


Mes_Recognise() {
  # description: recognise a value with a bracket expression by the "sed-eating" test :-)
  # arguments:  value  bracket_expression
  #+            $1
  #+                    probed value
  #+            $2
  #+                    bracket expression
  #+
  # return values: 0 - value fits the expression
  #+               1 - value not recognised
  # note: recognising is very strict now - even white space characters must
  #+      be included in the bracket expression
  #local fn=Mes_Recognise    # function name

  local fn2=Mes_Recognise    # function name

  # argument checks
  [ -z "$2" ] && Mes_Errr "$fn2: Specify a bracket expression."

  if [ -z "$1" ]; then
    Mes_Warnng "$fn2: An empty value."
    return 2
  fi

  # this one did not count white characters
  #[ `echo "$value" | sed "s/[$ex]//g" | wc -w` -eq 0 ]

  # be extra strict and count white characters
  #
  [ `echo "$1" | sed "s/[$2]//g" | wc -L` -eq 0 ]

  return $?
}




Mes_Recognise_Stringently() {
  # description: recognise a value with a bracket expression by the "sed-eating" test :-)
  #+             and exit with an explanation if the test was unsuccessful
  # arguments:  value   bracket_expression   [message]
  #+            $1
  #+                    probed value
  #+            $2
  #+                    bracket expression
  #+            $3
  #+                    message
  #+
  # return values: 0 - value fits the bracket exp.
  #+               1 - value not recognised
  # function name is not defined but reused

  local fn2=Mes_Recognise_Stringently    # function name

  # argument checks
  [ $# -lt 2 ] && Mes_Errr "$fn2: Number of arguments is less than 2."

  # local variables
  local msg    # message

  if [ -n "$3" ]; then
    msg="$fn2: '$3'"
  else
    msg="$fn2: Test of the value: '$1', with bracket expression: '$2', failed."
  fi

  Mes_Recognise "$1" "$2" || Mes_Errr "$msg"
}




Mes_Say() {
  # description: function simply outputs a chosen string as many times as specified
  # arguments:  [--line]  string number
  # return values: 0 always
  local fn=Mes_Say    # function name

  # argument checks
  [ $# -lt 2 ] && Mes_Errr "Use 2 arguments: [--line]  string number"

  # local variables
  local line=false    # ouput a single line

  if [ "$1" = --line ]; then
    line=true
    shift
  fi

  head -n$2 < <( yes -- "$1" ) | \
    \
    if $line; then
      sed -n '1h; 2,$H;
              $ { x; s/\n//g; p }'
    else
      cat
    fi

  return 0
}




Mes_Randomise() {
  # description: read lines from stdin and output them in a radomised order to stdout
  #+             the data may be provided as arguments too
  #+             suitable for randomising hundreds on lines
  # arguments: [--not-edacious]  [--ws]  [strings]
  #+            --not-edacious
  #+                    Read stdin only if requested by the hyphen sign '-'.
  #+            --ws
  #+                    Allow shell word splitting.
  # return values: mostly 0, I guess :-)
  local fn=Mes_Randomise    # function name

  # local variables
  local code=0    # return value
  local ws=""    # shell word splitting
  local edacious=""   # Read stdin only if requested by the hyphen sign '-'.
  local mes_input=()    # the default array used for reading the data
  local mes_shift_args    # the number of arguments to skip after option parsing
  local id    # array index
  local REPLY    # set as local to diminish interference with other 'while read' cycles

  Mes_Msg_Gag --on
  trap 'code=$(( $code + $? ))' ERR

  Mes_Msg 2 "Parsing cmdline options."
  Mes_Parse_Cmdline_Options '--not-edacious->edacious=--not-edacious
                             --ws->ws=--ws
                             ' "$@"
  shift $mes_shift_args

  Mes_Read  $edacious  $ws -- "$@"

  for id in ${!mes_input[@]}; do
    echo "$RANDOM ${mes_input[$id]}"
  done | \
    \
    sort -k1,1n | cut -d" " -f2-

  trap - ERR
  Mes_Msg_Gag --off
  return $code
}




Mes_Assemble_Regex() {
  # description: assembles a complex regular expression from cmdline arguments
  #+             or stdin
  # arguments: [--not-edacious] [--ws]  [-f|--format]  regexes
  #+            -f
  #+            --format
  #+                    an optional printf format
  #+            --not-edacious
  #+                    Read stdin only if requested by the hyphen sign '-'.
  #+            --ws
  #+                    Allow shell word splitting in the printf command.
  # return values: 0
  local fn=Mes_Assemble_Regex    # function name

  # local variables
  local code=0    # return value
  local format="^%s\$\\|"    # default format
  local edacious=""   # Read stdin only if requested by the hyphen sign '-'.
  local ws=""    # word splitting
  local mes_shift_args    # the number of arguments to skip after option parsing

  Mes_Msg_Gag --on

  Mes_Msg 2 "Parsing cmdline options."
  Mes_Parse_Cmdline_Options '-f->format
                             --format->format
                             --not-edacious->edacious=--not-edacious
                             --ws->ws=--ws
                             ' "$@"
  shift $mes_shift_args

  trap 'code=$(( $code + $? ))' ERR

  Mes_Printf  $edacious $ws "$format" "$@" | sed 's/[.\|.]\{2\}$//; s/[|]$//'

  trap - ERR
  Mes_Msg_Gag --off
  return $code
}




Mes_Printf() {
  # description: printf arguments or stdin
  # arguments:  [--not-edacious]  [--ws]  FORMAT  [arguments]
  #+            FORMAT
  #+                    printf format, compulsory
  #+            --not-edacious
  #+                    Read stdin only if requested by the hyphen sign '-'.
  #+            --ws
  #+                    Allow shell word splitting in the printf command.
  # return values: like printf
  local fn=Mes_Printf    # function name

  [ $# -eq 0 ] && Mes_Errr "Format is missing."

  # local variables
  local code=0    # return value
  local ws=""    # word splitting
  local edacious=""   # Read stdin only if requested by the hyphen sign '-'.
  local mes_input=()    # the default array used for reading the data
  local mes_shift_args    # the number of arguments to skip after option parsing

  Mes_Msg_Gag --on
  trap 'code=$(( $code + $? ))' ERR

  Mes_Msg 2 "Parsing cmdline options."
  Mes_Parse_Cmdline_Options '--not-edacious->edacious=--not-edacious
                             --ws->ws=--ws
                             ' "$@"
  shift $mes_shift_args

  Mes_Read  $edacious  $ws -- "${@:2}"

  printf "${1}" "${mes_input[@]}"

  trap - ERR
  Mes_Msg_Gag --off
  return $code
}




Mes_ManVar() {
  # description: Mes_Manipulate_Variable function, I have truncated its name, because I use it often
  #+             function performs basic operations with variables, adding, removal and checking of data
  #+             the variable may be an array item 'array[$id]'
  # arguments:  "variable"  [-i|--initialise]  [-u|--uniq]  [--ws]  [-f|--format]  [-v|--invert-match]  [-c|--count]  [--nl N]  [--check|--get|--add|--remove]  [values|sed_line_addresses|regexes]
  #+
  #+            "variable"
  #+                    Variable to manipulate with. When the var name is
  #+                    a content of some other variable specified as the
  #+                    first argument to Mes_ManVar, then this argument
  #+                    should be quoted.
  #+            -i
  #+            --initialise
  #+                    Initialise the variable and lose the previous contents
  #+                    for 'add|remove|other' actions.
  #+            -u
  #+            --uniq
  #+                    Make the var contents unique, implies sorting.
  #+            --ws
  #+                    Allow for word splitting in the operations.
  #+            -f
  #+            --format
  #+                    Printf format of the data. By default, the data
  #+                    is not formated and the input format is kept.
  #+                    The input format means: each argument on a separate line,
  #+                                            each stdin line on a separate line
  #+                    A newline is added to each format, so don't include
  #+                    a trailing new line unless you really know what you're doing.
  #+            -v
  #+            --invert-match
  #+                    Invert match for regexes and sed line addresses.
  #+            -c
  #+            --count
  #+                    Count the number of lines for regexes and sed line addresses.
  #+            --nl  N
  #+                    Output line numbers instead of items for '--get'. Numbering will start from N.
  #+                    Usefull for 'getting' line numbers using regex matching.
  #+            --check
  #+            --get
  #+            --add
  #+            --remove
  #+                    Actions to take.
  #+                    Check will use the first value only, does not save unified contents.
  #+                    Get does not save unified contents either.
  #+
  #+            values|sed_line_addresses|regexes
  #+                    May be new items, basic regular expressions or sed line addresses and address ranges.
  #+                    The regular expression must match whole lines,
  #+                    the starting circumflex and ending dollar sign
  #+                    are added.
  #+                    If there is no value argument stdin is read.
  #+                    
  # return values: 0 or 1 when checking
  #+               0 in other cases
  # note: when specifying a regular expression as an argument, use quotes
  # note: all array vars (not array items - vars with index 'array[id]') are
  #+      currently reduced to simple vars if modification (add|remove) is requested
  local fn=Mes_ManVar    # function name

  # argument checks
  [ $# -lt 2 ] && Mes_Errr "Usage:  "variable"  [-i|--initialise]  [-u|--uniq]  [--ws]  [-f|--format]  [-v|--invert-match]  [-c|--count]  [--nl N]  --check|--get|--add|--remove  [values|sed_line_addresses|regexes]"


  # local variables
  local var=""    # the variables name
  local mes_input=()    # input data - values, an array with values specified on command line of read from stdin
  local d    # delimiter, index in the 'mes_input' array where the previous variable content starts

  local initialise=false    # discard contents
  local uniq=false    # unify the contents
  local ws=false    # word splitting
  local format="%s"    # the default printf format
  local invert=false    # invert match for regexes and sed line addresses
  local count=false    # count lines
  local nl=""    # number lines
  local action=other    # action to take

  local mes_shift_args    # for the parse options function


  # read the var name first
  [ -z "$1" ] && Mes_Errr "The variable name, the first parameter, is empty."
  var="$1"
  shift

  Mes_Msg_Gag --on

  Mes_Parse_Cmdline_Options  '-u->uniq=true
                              --uniq->uniq=true

                              -i->initialise=true
                              --initialise->initialise=true

                              --ws->ws=true

                              -f->format
                              --format->format

                              -v->invert=true
                              --invert-match->invert=true

                              -c->count=true
                              --count->count=true
                              --nl->nl

                              --check->action=check
                              --get->action=get
                              --add->action=add
                              --remove->action=remove
                              ' "$@"
  shift $mes_shift_args

  Mes_Msg_Gag --off
  [ $action = get ] && Mes_Msg_Gag --on


  # deals with reading from both stdin and arguments
  #+data are read into the 'mes_input' array
  #
  Mes_Msg 2 "Reading input values."
  $ws && Mes_Msg 2 "Splitting words when reading."

  # set the word splitting flag
  #
  $ws && ws=--ws || ws=""

  Mes_Read $ws -- "$@"

  # set the index delimiter
  d=${#mes_input[@]}


  # get the previous content
  #
  if ! $initialise; then

    Mes_Read  $ws --add -- - \
      \
      < <( # distinguish between an array item and the rest - simple variable or array
           #+if we are dealing with an array item
           #+we want to modify the item but keep the rest of the array
           #
           # this not compatible with SL5 bash
           #if [[ $var =~ \[|\] ]]; then 

           if [[ `echo $var | grep -c "\[\|\]"` -eq 1 ]]; then
             # it is an array item '{array[id]}' if the item contains something
             #
             if [ `eval printf %s \""\\${$var}"\" | wc -c` -ne 0 ]; then
               eval printf \"%s\\n\" \""\${$var}"\"
             fi

           else
             # save the contents of an array if the array contains something
             #
             if [ `eval printf %s \""\\${$var[@]}"\" | wc -c` -ne 0 ]; then
               eval printf \"%s\\n\" \""\${$var[@]}"\"
             fi
           fi )
  fi


  #
  # if we are not dealing with an array item
  #+nuke the original array when the var is going to be modified
  #+'other' action is a request for unification or reformating
  #
  # this not compatible with SL5 bash
  #if [[ ! $var =~ \[|\]  &&  $action =~ add|remove|other ]]; then

  if [[ `echo $var | grep -c "\[\|\]"` -eq 0  &&  $action =~ add|remove|other ]]; then
    Mes_Msg 2 "Discarding the original array '$var'."
    eval $var=\(\)
  fi


  #### run the procedure to output messages only
  #
  Mes_Msg 2 "Proceeding with action: '$action'."

  Mes_Msg 2 "Line format: '$format'."

  $uniq && Mes_Msg 2 "Unifying the contents."
  $invert && Mes_Msg 2 "Invert regex selection."

  [ $action = remove ] && \
    if Mes_Recognise "`echo ${mes_input[@]::$d}`" "0-9,~+\\\$ "; then
      Mes_Msg 2 "Sed line address was recognised: '${mes_input[@]::$d}'."
    else
      Mes_Msg 2 "Grep regex was recognised: '${mes_input[@]::$d}'."
    fi
  #
  ##### end


  # convert invert into the '-v' grep flag
  #
  $invert && invert=-v || invert=""


  #### do the action now
  #
  case $action in

    check)
      [ `grep  $invert  -c "\`Mes_Assemble_Regex "${mes_input[@]::$d}"\`"` -ge 1 ]
      return $?
      ;;


    get)
      if [ -n "$nl" ]; then
        nl -nln -s" " -v$nl
      else
        cat
      fi | \
        \
        \
        #
        # do not recognise 'sed' line addresses when '--nl' is requested
        #
        if  Mes_Recognise "`echo ${mes_input[@]::$d}`" "0-9,~+\\\$ "  && \
              [ -z "$nl" ] ; then
          if [ -n "$invert" ]; then
            sed  "`echo ${mes_input[@]::$d} | sed 's/[$0-9]\+[,+~]*[$0-9]*/&d; /g'`"
          else
            sed -n "`echo ${mes_input[@]::$d} | sed 's/[$0-9]\+[,+~]*[$0-9]*/&p; /g'`"
          fi
        #
        # grep regex was recognised, or the line number was requested
        #
        else
          if [ -n "$nl" ]; then
            grep  $invert  "`Mes_Assemble_Regex  --format "^[0-9][0-9]*[[:blank:]]*%s\$\\|"  "${mes_input[@]::$d}"`" | cut -d" " -f1
          else
            grep  $invert  "`Mes_Assemble_Regex "${mes_input[@]::$d}"`"
          fi
        fi | \
          \
          \
          if $count; then
            wc -l
          else
            cat
          fi
      ;;


    add|remove|other)
      Mes_Msg 2 "Storing '$var'."
      eval $var=\"\`cat\`\"
      ;;


  esac \
    \
    \
    \
    < <( if [ ${#mes_input[@]} -gt $d ]; then
           #
           # send the previous variable contents first
           # bash arrays are indexed from 0, hence delimiter can be used directly
           #
           printf "${format}\n" "${mes_input[@]:$d}"
         fi | \
           \
           case $action in
             (remove)
               if  Mes_Recognise "`echo ${mes_input[@]::$d}`" "0-9,~+\\\$ "; then
                 if [ -n "$invert" ]; then
                   sed -n "`echo ${mes_input[@]::$d} | sed 's/[$0-9]\+[,+~]*[$0-9]*/&p; /g'`"
                 else
                   sed  "`echo ${mes_input[@]::$d} | sed 's/[$0-9]\+[,+~]*[$0-9]*/&d; /g'`"
                 fi
               else
                 # switch the invert flag here, we are removing
                 [ -n "$invert" ] && invert="" || invert=-v

                 grep  $invert  "`Mes_Assemble_Regex "${mes_input[@]::$d}"`"
               fi
               ;;

             (*)
               cat

               if [ $action = add ] && [ $d -gt 0 ]; then
                 printf "${format}\n" "${mes_input[@]::$d}"
               fi
               ;;

             #  # the list delimiter requires bash 4
             #  ;;&

             #(add)
             #  if [ $d -gt 0 ]; then
             #    printf "${format}\n" "${mes_input[@]::$d}"
             #  fi
             #  ;;
           esac | \
             \
             if $uniq; then
               sort -u
             else
               cat
             fi )


  Mes_Msg_Gag --off
  return 0
}




################################################################################
# I/O for files, stdin
################################################################################


Mes_Read() {
  # description: read standard input or command line arguments and deposit
  #+             them into an array variable or a specified simple variable
  # arguments:  [-a|--add]  [--not-edacious]  [--ws]  [--name|--var variable]  [input_data]
  #+            -a
  #+            --add
  #+                    Do not initialise the variable, but add lines instead.
  #+            --not-edacious
  #+                    Read stdin only if requested by the hyphen sign '-'.
  #+            --ws
  #+                    Allow shell word splitting.
  #+            --var
  #+            --name
  #+                    Deposit data into this variable. May less efficient
  #+                    than using Mes_ManVar for this purpose.
  #+            input_data
  #+                    '-' makes the function read the stdin.
  #+
  # return values: 0
  local fn=Mes_Read    # function name

  # local variables
  local code=0    # return value
  local add=false    # initiate the variable
  local edacious=true   # Read stdin only if requested by the hyphen sign '-'.
  local ws=false    # shell word splitting
  local var=""    # optional variable name
  local arg    # argument
  local contents    # contents of uninitialised variables
  local REPLY    # set as local to diminish interference with other 'while read' cycles
  local id    # REPLY array index
  local mes_shift_args    # for the parse options function

  Mes_Msg 2 "Parsing cmdln options."
  Mes_Parse_Cmdline_Options '-a->add=true
                             --add->add=true
                             --not-edacious->edacious=false
                             --ws->ws=true
                             --var->var
                             --name->var
                             ' "$@"
  shift $mes_shift_args

  trap 'code=$(( $code + $? ))' ERR


  #
  # define the array as local here if the contents is going to be stored in a different var
  # 'mes_input' is the default array used for reading the data
  #
  [ -n "$var" ] && local -a mes_input


  #
  # initialise vars if requested
  #
  if ! $add; then
    if [ -n "$var" ]; then
      Mes_Msg 2 "Initialising '$var'."
      eval $var=\"\"
    fi

    Mes_Msg 2 "Initialising 'mes_input'."
    mes_input=()

  elif [ -n "$var" ]; then
    Mes_Msg 2 "Initialising 'mes_input'."
    mes_input=()
  fi


  if [ -n "$var" ]; then
    Mes_Msg 2 "Reading into '$var'."
  else
    Mes_Msg 2 "Reading into 'mes_input'."
  fi

  # convert the word splitting flag
  $ws && ws="-a REPLY" || ws=""

  # It's probably the 'read' command what leaves out backslashes
  #+or it is the process substitution
  #+that's why the backslash substitution
  #
  while read  $ws ; do
    for id in ${!REPLY[@]}; do
      if [ -n "$var" ]; then
        eval contents=\""\$$var"\"

        if [ -z "$contents" ]; then
          eval $var=\"\${REPLY[\$id]}\"
        else
          # it is necessary to write the command like this if I don't want to use 'echo'
          eval $var="\"\$contents
\${REPLY[\$id]}\""
        fi

      else
        mes_input[${#mes_input[@]}]="${REPLY[$id]}"
      fi
    done
  done < <( if [ $# -gt 0 ]; then
              for arg do
                if [ "$arg" = - ]; then
                  sed 's/\\/\\\\/g'
                else
                  echo "${arg//\\/\\\\}"
                fi
              done
            elif $edacious; then
              sed 's/\\/\\\\/g'
            fi )

  trap - ERR
  return $code
}




Mes_Read_File() {
  # description: read a part of the specified file, substitue tabs for 8 spaces and
  #+             write it to the stadard output
  #+             function support autodetection and transparent reading of
  #+             gzip, bzip2 compressed files
  # arguments: [-q|--quiet] [--noexpand] [--array --squeeze -m|--max-count NUM --shave] [--re1 regex1] [--re2 regex2] [-a|--all]  [--path PATH] filenames
  #+
  #+detection of files:
  #+            -q
  #+            --quiet
  #+                    No warning messages.
  #+            --strict
  #+                    Exit when one of the files is not found.
  #+
  #+format of the output:
  #+            --noexpand
  #+                    Do not expand tabs.
  #+            --array
  #+                    prepare file for array - quote start and end of each
  #+                    line, hence each line will be one array element. Delete
  #+                    empty lines too.
  #+            -s
  #+            --squeeze
  #+                    reduce multiple spaces and delete empty lines
  #+
  #+parts to output:
  #+            --head NUM
  #+                    Stop reading a file after NUM [matching] lines from the start.
  #+                    This options reads only the part necessary not the whole file if no regex matching is requested.
  #+            --tail NUM
  #+                    Stop reading a file after NUM [matching] lines from the end.
  #+                    This options reads only the part necessary not the whole file if no regex matching is requested.
  #+            -v
  #+            --invert-match
  #+                    Invert grep matching for the single regex specified.
  #+            --shave
  #+                    delete lines with regex1 and 2
  #+
  #+            --regex regex1
  #+            --re1 regex1
  #+                    All regexes must be basic.
  #+                    if only the first regex is specified
  #+                    all lines containing this regex will be
  #+                    read. Shave doesn't apply in this case.
  #+                    'grep' processes these requests.
  #+
  #+            --re1 regex1
  #+            --re2 regex2
  #+                    read only a part of the file between occurences of
  #+                    these two regular expressions
  #+                    Processed by 'sed'.
  #+
  #+files to read:
  #+            --path PATH
  #+                    Read files in this directory.
  #+            -a
  #+            --all
  #+                    Test all files matching the name specified.
  #+            filename
  #+                    read from cmdline
  #+
  # return values: 1 - file missing
  #+               0 otherwise
  local fn=Mes_Read_File    # function name

  # argument checks
  [ $# -eq 0 ] && Mes_Errr "Specify a file to read."

  # local variables
  local code=0    # return value
  local mes_shift_args    # for the parse options function
  local quiet=false    # no warning messages
  local strict=false    # exit when file is not found

  local expand=true    # expand tabs
  local array=false    # prepare output for arrays, each line will be one element
  local squeeze=false    # trigger space squeezing

  local head=""    # stop after reading NUM matching lines from the start
  local tail=""    # stop after reading NUM matching lines from the end
  local invert=false    # invert grep matching
  local r1=".*"    # regex 1
  local r2=""    # regex 2
  local shave=false    # delete lines with regex1 and 2

  local path="."    # read from path
  local all=""    # test all files matching the name
  local arg    # argument

  local tested    # only existing non-zero files
  local REPLY    # set as local to diminish interference with other 'while read' cycles

  Mes_Msg_Gag --on
  Mes_Msg 2 "Parsing cmdln options."

  Mes_Parse_Cmdline_Options '-q->quiet=true
                             --quiet->quiet=true
                             --strict->strict=true

                             --noexpand->expand=false

                             --array->array=true

                             -s->squeeze=true
                             --squeeze->squeeze=true

                              -v->invert=true
                              --invert-match->invert=true

                             --head->head
                             --tail->tail

                             --shave->shave=true

                             --path->path
                             -a->all=--all
                             --all->all=--all

                             --regex->r1
                             --re1->r1
                             --re2->r2
                             ' "$@"
  shift $mes_shift_args

  trap 'code=$(($code + $?))' ERR

  [ -n "$head" ] && Mes_Recognise_Stringently  "$head" 0-9
  [ -n "$tail" ] && Mes_Recognise_Stringently  "$tail" 0-9
  [ -n "$head" ] && [ -n "$tail" ] && Mes_Errr "Specify either a head or a tail but not both."


  Mes_Msg 2 "Action taken: shave-array-squeeze $shave-$array-$squeeze."

  # convert the quiet flag
  $quiet && quiet=--quiet || quiet=''
  #
  # strict flag
  $strict && strict=--strict || strict=''
  #
  # convert invert into the '-v' grep flag
  $invert && invert=-v || invert=""

  # WARNNING
  # there is a problem that the pipe gives an error exit status of 141 when the function is run with the --head option
  #
  #+SOLUTION
  #+It is a combination of the head command and the program that reads the file because head sends
  #+a message to the program to finish reading the file when head is done with output and the exit code is 141.
  #+e.g. bzip2 -dc file | head -n5
  #+
  #+The solution is to make the reading command and all commands on the way to the head command insensitive with Mes_No_Err_Trap.
  #+OR disable the pipefail
  #
  #set -o pipefail

  #
  # pipe description:
  #+    the first command outputs filenames
  #+    the second deals with gzip, bzip2 support
  #+    3rd and 4th with the number of lines to output and regex searching
  #+    5th and 6th with reformating of the lines
  #
  Mes_Test_File  $quiet $strict $all --path $path  -s -- "$@" | \
    \
    \
    while read; do
      #
      # determine the file type: ascii, gzip, bzip2
      #
      if [ "`file -b "$REPLY" | cut -d"," -f1`" = "gzip compressed data" ]; then
        gzip -dc "$REPLY"

      elif [ "`file -b "$REPLY" | cut -d"," -f1`" = "bzip2 compressed data" ]; then
        bzip2 -dc "$REPLY"

      else
        cat "$REPLY"
      fi
    done | \
      \
      \
      if [ -z "$r2" ] && [ "$r1" = ".*" ]; then
        #
        # make processing of very long files much more efficient if no regex search was requested
        #
        cat

      elif [ -z "$r2" ]; then
        grep  $invert "$r1"

      elif $shave; then
        sed -n "/$r1/,/$r2/{ /$r1/d; /$r2/d; p }"

      else
        sed -n "/$r1/,/$r2/p"
      fi | \
        \
        \
        if [ -n "$head" ]; then
          head -n$head

        elif [ -n "$tail" ]; then
          tail -n$tail

        else
          cat
        fi | \
          \
          \
          if $expand; then
            expand
          else
            cat
          fi | \
            \
            \
            case $array-$squeeze in
              true-true)
                sed "/^ *\$/d; s/^  *//; s/ \+/ /g; s/^/'/; s/\$/'/"
                ;;
              false-true)
                sed '/^ *$/d; s/^  *//; s/ \+/ /g;'
                ;;
              true-false)
                sed "/^ *\$/d; s/^/'/; s/\$/'/"
                ;;
              false-false)
                cat
                ;;
            esac
           
  #set +o pipefail

  Mes_Msg_Gag --off
  trap - ERR
  return $code
}




Mes_Test_File() {
  # description: examine arguments by a selected test and return filenames
  #+             for the selected subset either that one which passed or
  #+             the other
  #+             function is good for testing multiple files at once
  # arguments: [-q|--quiet] [-v|--invert-match] [-a|--all] [--path PATH] [--status]  -d|-f|-s  NAME
  #+
  #+            -q
  #+            --quiet
  #+                    No warning messages.
  #+
  #+how to perform the test:
  #+            -d
  #+                    Test for an existing directory.
  #+            -f
  #+                    file
  #+            -s
  #+                    non-zero size file
  #+            --loose
  #+                    Perform a loose test for:
  #+                            p ... prefix '*arg'.
  #+                            s ... suffix 'arg*'.
  #+                            b ... both '*arg*'.
  #+            -v
  #+            --invert-match
  #+                    Return the subset which does not pass the test.
  #+
  #+what to output, filenames by default:
  #+            --status
  #+                    Output return status for each item instead of the
  #+                    selected filename subset.
  #+            --strict
  #+                    Output an error code and exit when one one the files is not found.
  #+                    Exit when the file is found in the invert mode.
  #+
  #+files to test:
  #+            --path PATH
  #+                    Perform the test in this directory.
  #+            -a
  #+            --all
  #+                    Test all files matching the name specified.
  #+            NAME
  #+                    String will be processed with shell pathname expansion.
  #+
  # return values: 0 always
  local fn=Mes_Test_File    # function name

  # argument checks
  [ $# -lt 1 ] && Mes_Errr "Specify the action at least."

  # local variables
  local mes_shift_args    # for the parse options function
  local code=0    # exit code
  local quiet=false    # no warning messages
  local strict=false    # exit when file is not found
  local invert=false    # return the other subset
  local loose=none    # loose test
  local all=false    # test all files matching the name
  local path="."    # change to path
  local status=false    # output return values and not filenames
  local good_boys=()    # arguments which pass the test
  local bad_girls=()    # arguments which do NOT pass the test
  local test=""    # test to perform
  local mes_input=()    # the default array used for reading the data
  local id    # index
  local prefix    # path prefix
  local REPLY    # set as local to diminish interference with other 'while read' cycles

  Mes_Msg_Gag --on

  Mes_Msg 2 "Parsing cmdln options."
  Mes_Parse_Cmdline_Options '-q->quiet=true
                             --quiet->quiet=true

                             -d->test=d
                             -f->test=f
                             -s->test=s
                             --loose->loose
                             -v->invert=true
                             --invert-match->invert=true

                             --status->status=true
                             --strict->strict=true

                             --path->path
                             -a->all=true
                             --all->all=true
                             ' "$@"
  shift $mes_shift_args

  [ -z "$test" ] && Mes_Errr "No test to perform."

  Mes_Read  --not-edacious -- "$@"

  for id in ${!mes_input[@]}; do
    #
    # add the speficied path to the item to be tested
    #+test absolute path in the item, do not add anything in this case
    #
    if [[ ${mes_input[$id]} =~ ^/ ]] || [ "$path" = . ]; then
      prefix=""
    else
      prefix="${path%/}/"
    fi


    while read; do
      #
      # if the files/dirs don't exist, the input is used
      #
      [ -${test} "$REPLY" ]
      code=$?

      if [ $code -eq 0 ]; then
        # exit in the strict mode
        $strict && { $invert && Mes_Errr "  '-${test}' test failed for '$REPLY'."; }

        # warning message
        $invert && { $quiet || Mes_Warnng "  '-${test}' test succeeded for '$REPLY'."; }

        # status mode
        $status && { $invert && echo 1 || echo 0; }

        if [ $test = d ]; then
          good_boys[${#good_boys[@]}]="${REPLY%/}"
        else
          good_boys[${#good_boys[@]}]="$REPLY"
        fi

      else
        # exit in the strict mode
        $strict && { $invert || Mes_Errr "  '-${test}' test failed for '$REPLY'."; }

        # warning message
        $invert || { $quiet || Mes_Warnng "  '-${test}' test failed for '$REPLY'."; }

        # status mode
        $status && { $invert && echo 0 || echo 1; }

        if [ $test = d ]; then
          bad_girls[${#bad_girls[@]}]="${REPLY%/}"
        else
          bad_girls[${#bad_girls[@]}]="$REPLY"
        fi
      fi
    done  \
      \
      \
      < <( { # prevent the ls command to test empty strings
             #+ls -d outputs . for an empty string
             #
             if [ -n "${mes_input[$id]}" ]; then
               #
               # loose option, perform a pathname expansion not included in the input string
               #
               case $loose in
                 (p)
                   eval ls -1 -d "$prefix"*"${mes_input[$id]}"  2> /dev/null
                   ;;
                 (s)
                   eval ls -1 -d "$prefix""${mes_input[$id]}"*  2> /dev/null
                   ;;
                 (b)
                   eval ls -1 -d "$prefix"*"${mes_input[$id]}"*  2> /dev/null
                   ;;
                 (none)
                   #
                   # search for multiple files only with pathname expansion
                   #+characters included optionally in the input string
                   #
                   eval ls -1 -d "$prefix""${mes_input[$id]}"  2> /dev/null
                   ;;
               esac
               c=$?

             else
               c=1
             fi

             # use the input value when nothing is found
             #
             if [ $c -gt 0 ]; then
               echo "${mes_input[$id]}"
             fi
           } | \
             \
             if $all; then
               cat
             else
               head -n1
             fi )
  done

  Mes_Msg_Gag --off

  $status && return 0
  

  # print otherwise
  if $invert; then
    [ -n "$bad_girls" ] && printf "%s\n" "${bad_girls[@]}"
  else
    [ -n "$good_boys" ] && printf "%s\n" "${good_boys[@]}"
  fi

  return 0
}




################################################################################
# Miscellaneous functions
################################################################################


Mes_No_Err_Trap() {
  # description: disable the current trap setting, execute a command and reset the trap again
  # arguments: [-q|--quiet] command
  # return values: 0 always
  local fn=Mes_No_Err_Trap    # function name

  # argument checks
  [ $# -eq 0 ] && Mes_Errr "Need a command to execute" 

  # local variables
  local quiet=false    # no messages
  local trap_cmd=""    # the trap command to reset the trap
  local sse=""    # shell setting for errtrace
  local mes_shift_args=""    # the number of arguments to skip after option parsing

  Mes_Msg_Gag --on

  Mes_Parse_Cmdline_Options '--quiet->quiet=true
                             -q->quiet=true
                             ' "$@"
  shift $mes_shift_args

  Mes_Msg_Gag --off
  $quiet && Mes_Msg_Gag --on

  # get the current shell setting
  sse="`set +o | grep errtrace`"
  trap_cmd="`trap -p ERR | sed "s/'/\\'/g"`"

  # disable the trap
  set +E
  trap - ERR

  if [ -n "$trap_cmd" ]; then
    Mes_Msg 2 "Trapping ERR signals is disabled for: $@"
    eval "$@"

    Mes_Msg 2 "Trapping ERR signals is restored to: $trap_cmd."
    eval $trap_cmd
  else
    eval "$@"
  fi

  if [[ $sse =~ -o ]]; then
    Mes_Msg 2 "Shell setting for errtrace restored to: $sse."
    $sse
  fi

  $quiet && Mes_Msg_Gag --off

  return 0
}




Mes_Query() {
  # description: function asks user a question, provides default answer
  #+             records users answer and compares it with the possible answers
  #+             if the comprison fails, user is prompted for an answer again
  # arguments: [--repeat N] [-q|--quiet] [-i|--iw]  variable_name   question   default_answer  [other_possible_answers]
  #+            --repeat N
  #+                    Repeat the query N times.
  #+            -q
  #+            --quiet
  #+                    No messages, no questions.
  #+            -i
  #+            --iw
  #+                    Ignore white spaces in the replies.
  #+
  # return values: 1 - repetition count run out
  #+               0 otherwise
  # note: the question has to be quoted to be treated as a single positional parameter
  # note: when an empty string is used instead of the variable name
  #+      the variable REPLY stays set for any possible reuse
  local fn=Mes_Query    # function name

  # argument checks
  [ $# -lt 3 ] && Mes_Errr "Provide: variable_name  question  default_answer [other_possible_answers]."

  # local variables
  local arg    # argument
  local repeat=999    # repetition
  local quiet=false    # no messages
  local iw=false    # ignore white spaces
  local mes_shift_args    # for the parse options function


  Mes_Msg 2 "Parsing cmdln options."
  Mes_Parse_Cmdline_Options '--repeat->repeat
                             -q->quiet=true
                             --quiet->quiet=true
                             -i->iw=true
                             --iw->iw=true
                             ' "$@"
  shift $mes_shift_args
  Mes_Recognise_Stringently  "$repeat" 0-9


  until [ $repeat -eq 0 ] ; do
    # use 'echo' because this is an interactive function
    #! $quiet && [ ${MES_VERBOSITY:-0} -ne 0 ] && echo -en "$2 [$3]: "
    ! $quiet && echo -en "$2 [$3]: "

    read -e

    # assign the default value
    [ -z "$REPLY" ] && REPLY="$3"

    # checking the answer for all possible responses
    for arg in ${@:3}; do

      if $iw; then
        Mes_Recognise "$REPLY" "$arg "
      else
        Mes_Recognise "$REPLY" "$arg"
      fi

      if [ $? -eq 0 ]; then
        if [ -n "$1" ]; then 
          #
          # assigning the user answer if some variable was specified
          #
          Mes_ManVar  $1 --initialise --add "$REPLY"
          $quiet || eval Mes_Msg 1 \"User: $1=\$\{$1\}\"

        else
          $quiet || Mes_Msg 1 "User: $REPLY"
        fi

        return 0
      fi
    done

    Mes_Warnng "Please enter '`printf "%s" "${3}"; [ -n "${4}" ] && printf "   or   %s" "${@:4}"`'."
    ((--repeat))
  done

  # the case with restricted repeats returns a wrong value of the default variable
  REPLY=""

  Mes_Warnng "The maximum query repeat count reached."
  return 1
}




Mes_Step_Info() {
  # description: returns various information from the steps data file
  #+             steps data file must be read in the 'mes_steps_file' variable
  # arguments: [OPTIONS]  [--re REGEX]  [STEP]
  #+            --number
  #+                    return numbers of the selected steps
  #+            --name
  #+                    return the name of the selected step
  #+            --dir
  #+                    return the directory for the selected step
  #+            --tasks
  #+                    return task script basenames
  #+            --max
  #+                    return the maximal step number
  #+            --re
  #+                    regular expression filtering
  #+            STEP
  #+                    step/s in the sed address format, e.g. '1,$' or 2
  #+                    the default is the current step 'mes_step'
  #+
  # return values: 1 - mes_steps_file not set
  #+               0 otherwise
  local fn=Mes_Step_Info    # function name

  # argument checks
  [ -z "$mes_steps_file" ] && Mes_Errr "Steps data is not available, 'mes_steps_file' array is empty."

  # local variables
  local code=0    # return value
  local action=name    # action to perform
  local re=""    # regex
  local mes_shift_args    # the number of arguments to skip after option parsing

  Mes_Msg_Gag --on
  trap 'code=$(( $code + $? ))' ERR

  Mes_Msg 2 "Parsing cmdline options."
  Mes_Parse_Cmdline_Options '--name->action=name
                             --number->action=number
                             --dir->action=dir
                             --tasks->action=tasks
                             --max->action=max
                             --re->re
                             ' "$@"
  shift $mes_shift_args

  case $action in
    max)
      echo "1,\$"
      ;;
    *)
      if [ -n "$1" ]; then
        echo "$@"
      elif [ -n "$re" ]; then
        echo "1,\$"
      elif [ -n "$mes_step" ]; then
        echo $mes_step
      else
        echo ""
      fi
      ;;
  esac | \
    \
    Mes_ManVar  mes_steps_file  --get | \
      \
      if [ -n "$re" ]; then
        grep "$re"
      else
        cat
      fi | \
        \
        case $action in
          number)
            cut -d" " -f1 | sed 's/^[^0-9]*0*//'
            ;;
          name)
            cut -d" " -f2
            ;;
          dir)
            cut -d" " -f1,2 | sed 's/^[^0-9]*0*//' | Mes_Printf --ws "%02d-%s\n"
            ;;
          tasks)
            cut -d" " -f3-
            ;;
          max)
            wc -l
            ;;
        esac

  Mes_Msg_Gag --on
  trap - ERR
  return $code
}




Mes_Extract_Steps() {
  # description: check the steps - integers, order, maximal value
  # arguments: [OPTIONS] non-option arguments
  #+            --strict
  #+                    no default step values
  # return values: 1 - no steps
  local fn=Mes_Extract_Steps    # function name

  # local variables
  local code=0    # return value
  local c    # in function exit code
  local arg    # argument
  local i    # integers
  local strict=false    # no default values
  local steps=()    # all step numbers
  local mes_shift_args    # the number of arguments to skip after option parsing
  local REPLY    # set as local to diminish interference with other 'while read' cycles

  Mes_Msg_Gag --on
  trap 'code=$(( $code + $? ))' ERR

  Mes_Msg 2 "Parsing cmdline options."
  Mes_Parse_Cmdline_Options '--strict->strict=true
                             ' "$@"
  shift $mes_shift_args

  # pick integers and check maximal values
  Mes_ManVar  i --add \
    < <( for arg do
           if Mes_Recognise "$arg" "0-9,~+\\\$"; then
             #
             # test integers in the specified address
             #
             c=0
             while read; do
               [ $REPLY -gt 0 ] || c=1
               [ $REPLY -le `Mes_Step_Info  --max` ] || c=1
             done \
               < <( echo "$arg" | sed 's/[^0-9]/ /g' | Mes_Printf --ws "%d\n" )

             if [ $c -gt 0 ]; then
               Mes_Warnng "'$arg' is not a suitable step address."
             else
               echo "$arg"
             fi
           fi
         done )


  if [ -z "$i" ]; then
    $strict && Mes_Errr "No integers/step numbers were found."

    # it may be the case that no steps were specified, use all steps by default
    steps=( `Mes_Step_Info  --number "1,\$"` )

  else
    steps=( `Mes_Step_Info  --number $i` )
  fi


  printf "%d\n" ${steps[@]} | sort -u

  trap - ERR
  Mes_Msg_Gag --off
  return $code
}




Mes_Extract_Basenames() {
  # description: extract a base name for files with specified suffixes from
  #+             filenames read from stdin
  # arguments:  SUFFIXES
  # return values:
  local fn=Mes_Extract_Basenames    # function name

  # argument checks
  [ $# -eq 0 ] && Mes_Errr "Use a suffix to probe."

  # local variables
  local code=0    # return value
  local files    # input data read from stdin
  local bn    # basenames
  local arg    # argument
  local cmd    # sed command
  local missing    # missing files

  trap 'code=$(($code + $?)); return $code'  ERR
  Mes_Msg_Gag --on

  # read in filenames from stdin
  files="`cat`"

  # assemble a sed command to delete suffixes from filenames
  for arg do
    Mes_ManVar  cmd  --add "s/$arg\$//"
  done

  # get the basenames
  bn="`Mes_ManVar  files --get "${@/#/.*}" | \
         \
         sed "$cmd" | sort -u`"

  #
  # verify that there are all files for each basename present
  #+  generate an ideal file list and grep the files available out
  #
  Mes_ManVar  missing -i --add \
    \
    < <( #
         # an ideal file list
         #
         for arg do
           Mes_ManVar bn --ws -f "%s$arg" --get 1,\$
         done | \
           \
           grep -v "`#
                     # files we have
                     #
                     for arg do
                       Mes_ManVar bn --ws -f "%s$arg" --get 1,\$ | \
                         \
                         Mes_ManVar  files --get
                     done | \
                       \
                       Mes_Assemble_Regex -- - `" )


  if [ -n "$missing" ]; then
    Mes_Warnng "There are missing files: `echo; printf "  %s\n" $missing`"
    return 1
  fi

  # write the basenames out
  printf "%s\n" $bn

  trap - ERR
  Mes_Msg_Gag --off
  return $code
}




Mes_Detect_Suffix() {
  # description: extract the most frequently occuring suffix in filenames
  #+             read from stdin. The possible suffixes are specified as
  #+             arguments.
  # arguments:  SUFFIXES
  # return values:
  local fn=Mes_Detect_Suffix    # function name

  # argument checks
  [ $# -eq 0 ] && Mes_Errr "Use a suffix to probe."

  # local variables
  local code=0    # return value
  local files    # input data read from stdin

  Mes_Msg_Gag --on
  trap 'code=$(($code + $?)); return $code' ERR

  # read in filenames from stdin
  files="`cat`"

  printf ".*\\.%s\n" $@ | \
    \
    Mes_ManVar  files --get | \
      \
      sed 's/^.*\.//' | \
        \
        sort | uniq -c | sort -k1,1rn | \
          \
          sed -n '1 { s/^ *[^ ]\+ \+//; p }'

  trap - ERR
  Mes_Msg_Gag --off
  return $code
}


# AND THAT'S IT, the end of the script
