# Horovod
Horovod is a framework for distributed training on TensorFlow, Keras, PyTorch, and MXNet.
It constitutes an alternative to frameworks such as deeplearning4j, as [it can be ran on a Spark cluster](https://github.com/horovod/horovod/blob/master/docs/spark.md), as well as in a swarm of Docker containers or a Kubernetes cluster.
Scaling via Kubernetes allows also for the seamlessly training of models on both CPU and GPU resources.
Horovod uses the message-passing interface (MPI) to coordinate multiple workers, [here](https://github.com/horovod/horovod/blob/master/docs/concepts.md) is a quick introduction to the paradigm.
A job is instantiated from one master parameter server, and distributed to the workers.
Specifically, `mpirun` is used to spawn an openmpi process (See example [here](https://github.com/horovod/horovod/blob/master/docs/running.md)), for instance:
```
mpirun -np 4 \
    -H localhost:4 \
    -bind-to none -map-by slot \
    -x NCCL_DEBUG=INFO -x LD_LIBRARY_PATH -x PATH \
    -mca pml ob1 -mca btl ^openib \
    python train.py
```
this runs the Python train.py file on a host with 4 GPUs, i.e. on 4 workers (`-np 4`). Clearly, this means that the created Horovod cluster will be dedicated to the specific training task.  
An alternative approach used by other projects (e.g. Kubeflow) is to employ an [MPI Operator](https://github.com/horovod/horovod/blob/master/docs/running.md), to spawn the mpi process as custom K8s resource (crd).  

Code-wise, training with Horovod requires also a few minimal changes:  
1. initializing horovod (`hvd.init()`)  
2. setting the resources to be used for the worker as a configuration for the ML library in use  
3. wrapping the optimizer in a horovod distributed optimizer (`opt = hvd.DistributedOptimizer(opt)`)  
4. Training the model using the distributed optimizer  

See an example for MNIST with Keras [here](https://github.com/horovod/horovod/blob/master/examples/keras_mnist.py).
Code examples for parallelizing neural network training in Horovod are reported [here](https://github.com/horovod/horovod/tree/master/examples).
