function num_cells = monkey_area_cells(monkey, area)
%Returns how many cells monkey has in area

num_cells = [];

start_dir = strrep(mfilename('fullpath'), mfilename(), '');

cd('../helper_code/');
monkey = fix_monkey_case(monkey);
area = fix_area_case(area);
cd(start_dir);

switch monkey
    case 'Quincy'
        switch area
            case 'PITd'
                num_cells = 55;
            case 'LIP'
                num_cells = 43;
        end
    case 'Michel'
        switch area
            case 'PITd'
                num_cells = 53;
            case 'LIP'
                num_cells = 37;
        end
end
