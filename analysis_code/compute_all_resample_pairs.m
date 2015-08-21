function distr = compute_all_resample_pairs(vec1, vec2)
%Given two vectors, we compute a vector whose entries are all possible
%combinations of differences between elements of vec1 and vec2

if size(vec1, 1) ~= size(vec2, 1)
    error('The two vectors must have equal number of resamples!\n');
end

vec_length = size(vec1, 1) * size(vec2, 1); 

% fprintf('Vector will be of length %d\n', vec_length);

distr = [];

for index_v1 = 1 : size(vec1, 1)

    distr = vertcat(distr, vec1(index_v1) - vec2);
  
end
   
end

