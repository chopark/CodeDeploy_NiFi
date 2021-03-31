echo "${@: (-2) :1}"

expected=5
newex=$(($expected+1))
echo ${!newex}
