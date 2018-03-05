% Compute the log partition function for a square lattice
function [logZ_perSite] = partitionSQR(beta, bond_dim, log4_N)
    T = tensorSQR(beta);
    
    logZ_perSite = 0;
    log2_N = 2 * log4_N;
    factor = 1;
   
    for log2_n=log2_N:-1:2 % Log4 number of lattice sites
        % Split the tensor T into two copies of S
        [S, sigma1] = tensorSQRSplit(T, bond_dim);
        % Contract four copies of S around a loop to form the new T
        T = loopContractSQR(S);
        % We've normalized by sigma1, must add this
        logZ_perSite = logZ_perSite + factor * log(sigma1);
        factor = factor / 2;
    end
    
    % Contract the final tensors when only two remain
    T = ttt(T, T, [2, 4], [4, 2]);  % Contract left and right
    T = contract(T, 1, 2);          % Contract top and bottom
    T = contract(T, 1, 2);          % Contract top and bottom
    logZ_perSite = logZ_perSite + log(T);
end

function [T] = loopContractSQR(S)
    % T'_{ijkl} = sum_{i'j'k'l'} S_{i'j'i} S_{j'k'j} S_{k'l'k} S_{l'i'l}
    T1 = ttt(S, S, 2, 1); % T1_{i'ik'j} and T1_{k'ki'l}
    T = ttt(T1, T1, [1, 3], [3, 1]);
    
    err = norm(T - permute(T, [4, 3, 2, 1])) / norm(T);
    err = norm(T - permute(T, [3, 4, 2, 1])) / norm(T);
    err = norm(T - permute(T, [2, 1, 4, 3])) / norm(T);
    err = norm(T - permute(T, [2, 3, 4, 1])) / norm(T);
end

function [delta, nrm] = accuracyCheck(S, T)
    % T_{ijkl} = sum_m S_{ijm} S_{klm}
    Tapprox = ttt(S, S, 3, 3);
    diff = T - Tapprox;
    delta = norm(diff);
    nrm = norm(T);
    delta = delta / nrm;
end

function [S, sigma1] = tensorSQRSplit(T, bond_dim)
    i_dim = size(T, 1);
    j_dim = size(T, 2);
    k_dim = size(T, 3);
    l_dim = size(T, 4);
    assert(i_dim == j_dim && j_dim == k_dim && k_dim == l_dim);
    
    eps = 1E-3;
    
    % Turn the tensor T into a matrix for splitting
    T_ = tenmat(T, [1, 2], [3, 4]);
    
    % Take SVD of T
    [U, sigmas, V] = svd(T_.data);
    
    diags_ = diag(sigmas);
    diags_ = diags_(diags_ > eps * diags_(1));
    rank_ = length(diags_);
    
    % Truncate using the bond_dimension
    bond_dim = min(bond_dim, rank_);
    U_ = U(:,1:bond_dim);
    diags_ = sigmas(1:bond_dim, 1:bond_dim);
    S_ = U_ * sqrt(diags_);
    
    % Reshape into split tensor S
    S = tensor(S_);
    S = reshape(S, [i_dim, j_dim, bond_dim]);
    
    % Check that the approximation is accurate
    [err, mag] = accuracyCheck(S, T);
    fprintf('Relative Approximation Error (Tensor): %f / mag = %f\n', err, mag);
    
    % Normalize S and take out factor of sigma1
    sigma1 = diags_(1, 1);
    S = S / sqrt(sigma1);
    
    err = norm(S - permute(S, [2, 1, 3])) / norm(S);
    fprintf('Symmetry Break: %f\n', err);
end

function [T] = tensorSQR(beta)
    bond_matrix = [exp(beta) exp(-beta); exp(-beta) exp(beta)];
    [U, Sigma, V] = svd(bond_matrix);
    S = U * sqrt(Sigma) * V';
    
    % T_{ijkl} = sum_m S_{mi} S_{mj} S_{mk} S_{ml}
    T = tensor(zeros(2, 2, 2, 2));
    for i=1:2
        for j=1:2
            for k=1:2
                for l=1:2
                    for m=1:2
                        T(i,j,k,l) = T(i,j,k,l) + ...
                            S(m,i)*S(m,j)*S(m,k)*S(m,l);
                    end
                end
            end
        end
    end
end
