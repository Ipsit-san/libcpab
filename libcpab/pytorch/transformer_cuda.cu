#include <ATen/ATen.h>
#include <cuda.h>
#include <cuda_runtime.h>
#include "../core/cpab_ops.cuh"

#define DIV_UP(a, b) (((a) + (b)-1) / (b))

at::Tensor cpab_cuda_forward(at::Tensor points_in, 
                             at::Tensor trels_in,  
                             at::Tensor nstepsolver_in, 
                             at::Tensor nc_in, 
							 at::Tensor output){
    // Problem size
    const auto ndim = points_in.size(0);
    const auto nP = points_in.size(1);
    const auto batch_size = trels_in.size(0);        
    
    // Kernel configuration
    dim3 bc((int)ceil(nP/256.0), batch_size);
    dim3 tpb(256, 1);
    
    // Launch kernel
    // We do it in this way, since dynamically allocating memory in CUDA sucks!
    if(ndim == 1){
         cpab_cuda_kernel_forward_1D<<<bc, tpb>>>(nP, batch_size,
                                                  output.data<float>(),
                                                  points_in.data<float>(),
                                                  trels_in.data<float>(),
                                                  nstepsolver_in.data<int>(),
                                                  nc_in.data<int>());
	}
	if(ndim == 2){
         cpab_cuda_kernel_forward_2D<<<bc, tpb>>>(nP, batch_size,
                                                  output.data<float>(),
                                                  points_in.data<float>(),
                                                  trels_in.data<float>(),
                                                  nstepsolver_in.data<int>(),
                                                  nc_in.data<int>());
	}
	if(ndim == 3){
        	cpab_cuda_kernel_forward_3D<<<bc, tpb>>>(nP, batch_size,
                                                	 output.data<float>(),
                                                     points_in.data<float>(),
                                                     trels_in.data<float>(),
                                                     nstepsolver_in.data<int>(),
                                                     nc_in.data<int>());
    }                                  
    return output;           
}

at::Tensor cpab_cuda_backward(at::Tensor points_in, 
                              at::Tensor As_in, 
                              at::Tensor Bs_in, 
                              at::Tensor nstepsolver_in,
                              at::Tensor nc_in,
                              at::Tensor output){
                              
    // Problem size
    const auto n_theta = As_in.size(0);
    const auto d = Bs_in.size(0);
    const auto ndim = points_in.size(0);
    const auto nP = points_in.size(1);
    const auto nC = Bs_in.size(1);
    
    // Kernel configuration
    dim3 tpb = dim3(std::min((int)nP, 128), std::min((int)n_theta, 4), std::min((int)d, 1));
    dim3 bc = dim3(DIV_UP(nP, tpb.x), DIV_UP(n_theta, tpb.y), DIV_UP(d, tpb.z));
    dim3 vtc = dim3(nP, n_theta, d);
    
    // Launch kernel
    // We do it in this way, since dynamically allocating memory in CUDA sucks!
	if(ndim == 1){
         cpab_cuda_kernel_backward_1D<<<bc, tpb>>>(vtc, n_theta, d, nP, nC,
                                                   output.data<float>(), 
                                                   points_in.data<float>(), 
                                                   As_in.data<float>(), 
                                                   Bs_in.data<float>(),
                                                   nstepsolver_in.data<int>(), 
                                                   nc_in.data<int>());
	}
	if(ndim == 2){
         cpab_cuda_kernel_backward_2D<<<bc, tpb>>>(vtc, n_theta, d, nP, nC,
                                                   output.data<float>(), 
                                                   points_in.data<float>(), 
                                                   As_in.data<float>(), 
                                                   Bs_in.data<float>(),
                                                   nstepsolver_in.data<int>(), 
                                                   nc_in.data<int>());
	}
 	if(ndim == 3){
         cpab_cuda_kernel_backward_3D<<<bc, tpb>>>(vtc, n_theta, d, nP, nC,
                                                   output.data<float>(), 
                                                   points_in.data<float>(), 
                                                   As_in.data<float>(), 
                                                   Bs_in.data<float>(),
                                                   nstepsolver_in.data<int>(), 
                                                   nc_in.data<int>());
    }                                         
    return output;
}