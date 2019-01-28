# Using Dask to parallelize Python code from a multi-threaded to a multi-node cluster
Dask is a Python tool for data processing.
Dask redefines classic Python data structures for application developers, to map data operations on atomic tasks
and consequently task graphs, which can be scheduled and run on multi-threaded machines or clusters.

![](http://docs.dask.org/en/latest/_images/collections-schedulers.png)

Dask APIs are classified in: i) high level (collections) and ii) low-level (lazy function evaluation).

Once defined, a task graph can be displayed using the Graphviz library:
```
y.visualize(filename='example.svg')
```

In this README we want to show basic usage of Dask to scale existing sci-py code.
We refer to the [official Dask documentation](http://docs.dask.org/en/latest/) for a complete overview of Dask functionalities.

## 1. Dask collections
Dask introduces variants to classic Python data structures to achieve processing in those cases in which data does not fit in RAM.
This is achieved by sharding data in multiple partitions that are processed separately.

Specifically, Dask provides the following data structures:
* [Dask Arrays](http://docs.dask.org/en/latest/array.html) - a subset of numpy ndarrays, consisting of multiple arrays arranged in a grid
* [Dask Dataframes](http://docs.dask.org/en/latest/dataframe.html) - extends the Pandas dataframe
* [Dask Bags](http://docs.dask.org/en/latest/bag.html) - used to model composed objects like sequences and dictionaries as well as semi-structured data blobs;

## 2. Scheduling
Different schedulers can be used to run the task graphs (see [Documentation](http://docs.dask.org/en/latest/scheduling.html)):
* synchronous (single-thread) - cooperative scheduling with no parallelism offered; this can be used for debugging;
* multi-threaded - using a threadpool pattern to schedule multiple python threads; the performance limit is the Python global interpreter lock (GIL);
* multi-processing - using a threadpool pattern at process level to bypass the GIL performance bottleneck;
* distributed - using a scheduler to coordinate a cluster of worker nodes;

## 3. Dask Delayed

As mentioned, Dask low-level API includes means to delay function invokation by introducing lazy evaluation.  
This includes:
  1. [delayed](http://docs.dask.org/en/latest/delayed.html) - introduces lazy evaluation on general python functions, the workload can be triggered calling compute  
    * delayed - to add a lazy task for a common python function;  
    * to/from delayed - to convert results to and from Dask collections (delayed or futures);  
```
    @dask.delayed
    def inc(x):
      return x + 1

    @dask.delayed
    def add(x, y):
    return x + y

    a = inc(1)       # no work has happened yet
    b = inc(2)       # no work has happened yet
    c = add(a, b)    # no work has happened yet
    c = c.compute()  #  triggers the computations
```
  2. [futures](http://docs.dask.org/en/latest/futures.html) - similar to delayed, but the computation is ran directly, i.e. without waiting for compute to be called  
```
    from dask.distributed import Client
    client = Client()

    def inc(x):
      return x + 1

    def add(x, y):
      return x + y

    a = client.submit(inc, 1)     # work starts immediately
    b = client.submit(inc, 2)     # work starts immediately
    c = client.submit(add, a, b)  # work starts immediately

    c = c.result()                # block until work finishes, then gather result
```

## 4. Dask ML
[Dask ML](https://ml.dask.org/) is a collection of scalable ML algorithms for Dask. Beside that, Dask ML also provide a means to directly parallelize popular ML libraries, such as [scikit-learn](http://matthewrocklin.com/blog/work/2017/02/07/dask-sklearn-simple) and [xgboost](https://ml.dask.org/xgboost.html), using [Python Joblib](https://ml.dask.org/joblib.html).
