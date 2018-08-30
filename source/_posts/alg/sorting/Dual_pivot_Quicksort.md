---
title: Dual pivot Quicksort
date: 2018-04-27 14:55:52
categories:
- alg
tags:
- sorting
---


time: 2018-04-27 14:55:52

参考：https://www.geeksforgeeks.org/dual-pivot-quicksort/

>   The idea of dual pivot quick sort is to take two pivots, one in the left end of the array and the second, in the right end of the array. The left pivot must be less than or equal to the right pivot, so we swap them if necessary.
>
>   Then, we begin partitioning the array into three parts: in the first part, all elements will be less than the left pivot, in the second part all elements will be greater or equal to the left pivot and also will be less than or equal to the right pivot, and in the third part all elements will be greater than the right pivot. Then, we shift the two pivots to their appropriate positions as we see in the below bar, and after that we begin quicksorting these three parts recursively, using this method.
>
>   Dual pivot quick sort is a little bit faster than the original single pivot quicksort.But still, the worst case will remain O(n^2) when the array is already sorted in an increasing or decreasing order.

![An example](http://contribute.geeksforgeeks.org/wp-content/uploads/dual.png)





```C
// C program to implement dual pivot QuickSort
#include <stdio.h>

int partition(int* arr, int low, int high, int* lp);

void swap(int* a, int* b)
{
	int temp = *a;
	*a = *b;
	*b = temp;
}

void DualPivotQuickSort(int* arr, int low, int high)
{
	if (low < high) {
		// lp means left pivot, and rp means right pivot.
		int lp, rp; 
		rp = partition(arr, low, high, &lp);
		DualPivotQuickSort(arr, low, lp - 1);
		DualPivotQuickSort(arr, lp + 1, rp - 1);
		DualPivotQuickSort(arr, rp + 1, high);
	}
}

int partition(int* arr, int low, int high, int* lp)
{
    printf("------- begin partition --------\n");
	if (arr[low] > arr[high])
		swap(&arr[low], &arr[high]);
	// p is the left pivot, and q is the right pivot.
	int j = low + 1,g = high - 1;
	int k = low + 1, p = arr[low], q = arr[high];
	while (k <= g) {
	    printf("j: %d value: %d, g: %d value: %d, k: %d value: %d\n", j, arr[j], g, arr[g], k, arr[k]);

		// if elements are less than the left pivot
		if (arr[k] < p) {
			swap(&arr[k], &arr[j]);
			j++;
		}

		// if elements are greater than or equal 
		// to the right pivot
		else if (arr[k] >= q) {
			while (arr[g] > q && k < g)
				g--;
			swap(&arr[k], &arr[g]);
			g--;
			if (arr[k] < p) {
				swap(&arr[k], &arr[j]);
				j++;
			}
		}
		k++;
		for (int i = 0; i < 8; i++)
		    printf("%d ", arr[i]);
		printf("\n");
	}
	j--;
	g++;

	// bring pivots to their appropriate positions.
	swap(&arr[low], &arr[j]);
	swap(&arr[high], &arr[g]);

	// returning the indeces of the pivots.
	*lp = j; // because we cannot return two elements 
			// from a function.
    printf("------- end partition --------\n");
	return g;
}

// Driver code
int main()
{
	int arr[] = { 24, 8, 42, 75, 29, 77, 38, 57 };
	printf("24, 8, 42, 75, 29, 77, 38, 57\n");
	DualPivotQuickSort(arr, 0, 7);
	printf("Sorted array: ");
	for (int i = 0; i < 8; i++)
		printf("%d ", arr[i]);
	printf("\n");
	return 0;
}
```

```
24, 8, 42, 75, 29, 77, 38, 57
------- begin partition --------
j: 1 value: 8, g: 6 value: 38, k: 1 value: 8
24 8 42 75 29 77 38 57 
j: 2 value: 42, g: 6 value: 38, k: 2 value: 42
24 8 42 75 29 77 38 57 
j: 2 value: 42, g: 6 value: 38, k: 3 value: 75
24 8 42 38 29 77 75 57 
j: 2 value: 42, g: 5 value: 77, k: 4 value: 29
24 8 42 38 29 77 75 57 
j: 2 value: 42, g: 5 value: 77, k: 5 value: 77
24 8 42 38 29 77 75 57 
------- end partition --------
------- begin partition --------
j: 3 value: 38, g: 3 value: 38, k: 3 value: 38
8 24 29 38 42 57 75 77 
------- end partition --------
------- begin partition --------
------- end partition --------
Sorted array: 8 24 29 38 42 57 75 77 
```



## 总结

基本的处理流程：

1. 选定最低位和最高位作为轴 num，也就是有两个轴。

2. lowPoint = low + 1 和 highPoint = high - 1 作为选轴的开始点。

3. scanPoint = lowPoint 一直扫描到 highPoint， 如果 scanPoint_Value < low_Value : swap(lowPoint_Value, scanPoint_Value) elseif (scanPoint_Value >= high_Value) : swap(highPoint_Value, scanPoint_Value)

4. 最后 swap(low_Value, (lowPoint - 1).Value), swap(high_Value, (highPoint + 1)_Value)

   