function monkey_out = fix_monkey_case(monkey)
%Simply ensures that the case is correct for finding overview file

if strcmpi(monkey, 'michel')
    monkey_out = 'Michel';
elseif strcmpi(monkey, 'quincy')
    monkey_out = 'Quincy';
elseif strcmpi(monkey, 'both_monkeys')
    monkey_out = monkey;
else
    error('Monkey must be michel or quincy\n');
end