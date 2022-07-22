function matrix = replace_nan(matrix, value)
    matrix(isnan(matrix)) = value;
end