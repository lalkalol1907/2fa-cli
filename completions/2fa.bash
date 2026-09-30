# Bash completion for 2fa. Enable with:
#   eval "$(2fa completions bash)"

_2fa_filter() {
    local cur="$1"
    local cand
    shift
    COMPREPLY=()
    for cand in "$@"; do
        if [[ "$cand" == "$cur"* ]]; then
            COMPREPLY+=("$cand")
        fi
    done
}

_2fa_filenames() {
    builtin compopt -o filenames 2>/dev/null || true
}

_2fa_accounts() {
    local name
    _2fa_accounts_result=()
    while IFS= read -r name; do
        [[ -n "$name" ]] && _2fa_accounts_result+=("$name")
    done < <(TWOFA_COMPLETE=1 command 2fa 2>/dev/null)
}

# Bash 3.2 with `set -u` errors on an empty "${array[@]}".
_2fa_filter_accounts() {
    local cur="$1"
    shift
    if [[ ${#_2fa_accounts_result[@]} -gt 0 ]]; then
        _2fa_filter "$cur" "$@" "${_2fa_accounts_result[@]}"
    elif [[ $# -gt 0 ]]; then
        _2fa_filter "$cur" "$@"
    else
        COMPREPLY=()
    fi
}

_2fa() {
    local cur
    local -a positionals=()
    local word cmd copy=0 i

    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"

    _2fa_accounts

    for ((i = 1; i < COMP_CWORD; i++)); do
        word="${COMP_WORDS[i]}"
        case "$word" in
            -c|--copy)
                copy=1
                ;;
            -*)
                ;;
            *)
                positionals+=("$word")
                ;;
        esac
    done

    if [[ ${#positionals[@]} -eq 0 ]]; then
        if [[ "$copy" -eq 1 ]]; then
            _2fa_filenames
            _2fa_filter_accounts "$cur"
            return
        fi
        if [[ "$cur" == -* ]]; then
            _2fa_filter "$cur" -c --copy
            return
        fi
        _2fa_filter_accounts "$cur" add list rm completions
        return
    fi

    cmd="${positionals[0]}"
    case "$cmd" in
        add)
            # 2fa add <name> <qr-file>
            if [[ ${#positionals[@]} -eq 2 ]]; then
                _2fa_filenames
                local IFS=$'\n'
                COMPREPLY=($(compgen -f -- "$cur"))
            fi
            ;;
        rm)
            if [[ ${#positionals[@]} -eq 1 ]]; then
                _2fa_filenames
                _2fa_filter_accounts "$cur"
            fi
            ;;
        completions)
            if [[ ${#positionals[@]} -eq 1 ]]; then
                _2fa_filter "$cur" bash
            fi
            ;;
        list)
            ;;
        *)
            if [[ "$copy" -eq 0 ]]; then
                _2fa_filter "$cur" -c --copy
            fi
            ;;
    esac
}

complete -F _2fa 2fa
