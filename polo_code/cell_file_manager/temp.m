cell_str=LIP_cell;
monkey='Michel';
area='LIP';
for i=1:length(cell_str)
  cell_str(i).monkey=monkey;
  cell_str(i).area=area;
end
save([area '_' monkey '.mat'],'cell_str');