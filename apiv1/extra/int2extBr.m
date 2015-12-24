function [branch] = int2extBr(i2e,branch)
%% define names for columns to data matrices
[F_BUS, T_BUS] = idx_brch;

branch(:, F_BUS)            = i2e( branch(:, F_BUS)         );
branch(:, T_BUS)            = i2e( branch(:, T_BUS)         );