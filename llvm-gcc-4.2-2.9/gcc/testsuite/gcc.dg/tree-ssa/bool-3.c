/* { dg-do compile } */
/* { dg-options "-O1 -fdump-tree-optimized" } */
/* LLVM LOCAL test not applicable */
/* { dg-require-fdump "" } */

int f(_Bool x)
{
  int y;
  if (!x)
    y = 0;
  else
    y = 1;
  return y;
}

/* There should be no == 0. Though PHI-OPT or invert_truth does not
   fold its tree.  */
/* { dg-final { scan-tree-dump-times "== 0" 0 "optimized" { xfail *-*-* } } } */

/* { dg-final { cleanup-tree-dump "optimized" } } */
