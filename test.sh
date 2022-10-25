# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    test.sh                                            :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: chelmerd <chelmerd@student.42wolfsburg.de> +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2022/02/15 15:11:08 by chelmerd          #+#    #+#              #
#    Updated: 2022/10/25 12:34:34 by chelmerd         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

dir=$1

INT_MAX=2147483647
INT_MIN=$((-1 * $INT_MAX - 1))

source colors.sh

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
	# linux
	checker=checker_linux
elif [[ "$OSTYPE" == "darwin"* ]]; then
	# Mac OSX
	checker=checker_Mac
fi
NAME=$dir/push_swap
# NAME=$checker # debug

asc_nbrs()
{
	ruby -e "puts ($1..$2).to_a.join(' ')"
}

dsc_nbrs()
{
	ruby -e "puts ($1..$2).reverse_each.to_a.join(' ')"
}

rand_nbrs()
{
	ruby -e "puts ($1..$2).to_a.shuffle.take($3).join(' ')"
}

color_msg()
{
	echo -e $1 "$2" $DEFAULT
}

error_msg()
{
	color_msg $RED "$1"
}

ok_msg()
{
	color_msg $GREEN "$1"
}

info_msg()
{
	color_msg $CYAN "$1"
}

calc_score()
{
	local min=$INT_MAX
	local max=0
	local avg=0
	numbers=0
	while read line; do
		# echo $line
		avg=$((avg + $line))
		if [[ $line -lt min ]]; then
			min=$line
		fi
		if [[ $line -gt max ]]; then
			max=$line
		fi
		numbers=$((numbers+1))
	done < number_of_cmds.txt
	avg=$(echo "$avg / $numbers" | bc -l)
	cat number_of_cmds.txt | tr '\n' '\t'
	echo ""
	printf "$PURPLE min: %d max: %d avg: %.2f\n$DEFAULT" $min $max $avg
}

check_norme()
{
	if [[ `norminette | grep -c Error` -gt 0 ]]; then
		error_msg "Norm Error"
	else
		ok_msg "Norm OK"
	fi
}

expect_error()
{
	diff --brief out.txt error.txt
	if [[ $? != 0 ]]; then
		error_msg "no Error"
		diff out.txt error.txt >> results.txt
	else
		ok_msg "OK"
	fi
}

expect_empty_file()
{
	if [[ -s $1 ]]; then
		error_msg "file $1 not empty"
	else
		ok_msg "OK"
	fi
}

test()
{
	./$NAME $* &> out.txt
	# grep -E "^(pa|pb|ra|rb|rra|rrb|rr|rrr|sa|sb|ss)" out2.txt > out.txt # debug
}

check()
{
	./$checker $* < out.txt | grep -q OK
	if [[ $? != 0 ]]; then
		echo "KO - check failed $* was not sorted correctly" >> details.txt
		return 1
	fi
	return 0
}

check_number_of_cmds()
{
	if [[ $1 -gt $2 ]]; then
		error_msg "found $1 cmds, but only $2 are tolerated. $3"
		info_msg "$3"
		return 1
	fi
	return 0
}

test_error()
{
	test $*
	expect_error
}

test_error_on_stderr()
{
	./$NAME one 1> stdout.txt 2> out.txt
	expect_error
	expect_empty_file stdout.txt
}

test_error_management()
{
	color_msg $UNDERLINE "Error management"
	info_msg "error on stderr"
	test_error_on_stderr

	info_msg "non-numeric parameter"
	test_error one
	test_error 0 1 two 3
	test_error 0xFF
	test_error abc

	info_msg "duplicate number"
	test_error 1 1 0
	test_error 0 1 2 3 4 3
	test_error 0 1 2 -3 4 -3

	info_msg "max int"
	test $((INT_MAX)) 7 6 5
	test 1 $((INT_MAX)) 5
	test $((INT_MIN)) 7 6 5
	test 1 $((INT_MIN)) 5

	info_msg "greater than int"
	test_error $((INT_MAX + 1))
	test_error $((INT_MIN - 1))
	test_error 0 1 $((INT_MAX + 1))
	test_error $((INT_MIN - 1)) $((INT_MAX + 1))

	info_msg "expect nothing"
	test
	expect_empty_file out.txt
}

identity_test()
{
	color_msg $UNDERLINE "identity test"
	test 42
	expect_empty_file out.txt
	test 0 1 2 3
	expect_empty_file out.txt
	test 0 1 2 3 4 5 6 7 8 9
	expect_empty_file out.txt
}

test_simple_version()
{
	color_msg $UNDERLINE "simple version"
	test 2 1 0
	check 2 1 0
	number_of_cmds=$(cat out.txt | wc -l)
	if [[ $number_of_cmds -eq 2 || $number_of_cmds -eq 3 ]]; then
		ok_msg "OK - number of commands"
	else
		error_msg "number of commands is not 2 or 3"
	fi
}

test_all_permutaions()
{
	local error=0
	color_msg $UNDERLINE "$1 values"
	#test 1 3 2
	combo=$2
	threshhold=$3
	./permutations.sh $combo > permutations.txt
	while read line; do
		#echo $line
		test $line
		check $line
		local res=$?
		if [[ res != 0 ]]; then
			error=$((error + res))
		fi
		number_of_cmds=$(cat out.txt | wc -l)
		check_number_of_cmds $number_of_cmds $threshhold "$line"
		local res=$?
		if [[ res != 0 ]]; then
			error=$((error + res))
		fi
	done < permutations.txt
	if [[ $error != 0 ]]; then
		error_msg "$error error(s)"
	else
		ok_msg "errors = $error"
	fi
	info_msg "done testing all `cat permutations.txt | wc -l` permutations"
}

test_five()
{
	local error=0
	color_msg $UNDERLINE "5 values"
	#test 1 5 2 4 3
	./mytester/permutations.sh 12345 > permutations.txt
	while read line; do
		#echo $line
		test $line
		check $line
		local res=$?
		if [[ res != 0 ]]; then
			error=$((error + res))
		fi
		number_of_cmds=$(cat out.txt | wc -l)
		check_number_of_cmds $number_of_cmds 12 "$line"
		local res=$?
		if [[ res != 0 ]]; then
			error=$((error + res))
		fi
	done < permutations.txt
	if [[ $error != 0 ]]; then
		error_msg "$error error(s)"
	else
		ok_msg "errors = $error"
	fi
	info_msg "done testing all `cat permutations.txt | wc -l` permutations"
}

test_n()
{
	rm -f nbrs.txt
	rm -f number_of_cmds.txt
	n=$1
	threshhold=$2
	runs=$3
	local error=0
	color_msg $UNDERLINE "$n values"
	for ((i = 0 ; i < $runs ; i++)); do
		rand_nbrs -1000 1000 $n >> nbrs.txt
	done
	dsc_nbrs 1 $n >> nbrs.txt
	while read line; do
		# echo $line
		test $line
		check $line
		local res=$?
		if [[ res != 0 ]]; then
			error=$((error + res))
		fi
		number_of_cmds=$(cat out.txt | wc -l)
		# info_msg $number_of_cmds
		echo $number_of_cmds >> number_of_cmds.txt
		check_number_of_cmds $number_of_cmds $threshhold "$line"
		local res=$?
		if [[ res != 0 ]]; then
			error=$((error + res))
		fi
	done < nbrs.txt
	if [[ $error != 0 ]]; then
		error_msg "$error error(s)"
	else
		ok_msg "errors = $error"
	fi
	info_msg "done testing `cat nbrs.txt | wc -l` permutations"
	calc_score
}

setup()
{
	rm -f details.txt
	rm -f error.txt
	echo "Error" > error.txt
}

cleanup()
{
	rm -f nbrs.txt
	rm -f number_of_cmds.txt
	rm -f out.txt
	rm -f permutations.txt
	rm -f results.txt
	rm -f stdout.txt
}
setup
check_norme
# make -C $dir
# if [[ $? != 0 ]]; then
# 	error_msg "Make Error"
# 	exit 1
# fi
test_error_management
identity_test
test_simple_version
test_all_permutaions 3 123 2
test_all_permutaions 5 12345 12
# test_three
# test_five
test_n 100 1500 100
test_n 500 11500 10
cleanup
