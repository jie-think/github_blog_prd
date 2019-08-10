# sort

接口:

```go
// A type, typically a collection, that satisfies sort.Interface can be
// sorted by the routines in this package. The methods require that the
// elements of the collection be enumerated by an integer index.
// 元素集合的操作接口
type Interface interface {
	// Len is the number of elements in the collection.
    // 集合中元素的个数
	Len() int
	// Less reports whether the element with
	// index i should sort before the element with index j.
    // 元素 i 是否应该在元素 j 之前
	Less(i, j int) bool
	// Swap swaps the elements with indexes i and j.
    // 交换元素 i 和 j
	Swap(i, j int)
}
```

## Sort 接口

Sort 用的是快排

```go
func Sort(data Interface) {
	n := data.Len()
	quickSort(data, 0, n, maxDepth(n))
}
```



### quickSort()

```go
func quickSort(data Interface, a, b, maxDepth int) {
	for b-a > 12 { // Use ShellSort for slices <= 12 elements
		if maxDepth == 0 {
			heapSort(data, a, b)
			return
		}
		maxDepth--
		mlo, mhi := doPivot(data, a, b)
		// Avoiding recursion on the larger subproblem guarantees
		// a stack depth of at most lg(b-a).
		if mlo-a < b-mhi {
			quickSort(data, a, mlo, maxDepth)
			a = mhi // i.e., quickSort(data, mhi, b)
		} else {
			quickSort(data, mhi, b, maxDepth)
			b = mlo // i.e., quickSort(data, a, mlo)
		}
	}
	if b-a > 1 {
		// Do ShellSort pass with gap 6
		// It could be written in this simplified form cause b-a <= 12
		for i := a + 6; i < b; i++ {
			if data.Less(i, i-6) {
				data.Swap(i, i-6)
			}
		}
		insertionSort(data, a, b)
	}
}
```

大于12用快排,小于等于12插排, 为啥是12呢? (元素个数小于13时插入排序会比快排快吗?)



