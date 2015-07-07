-- Date: June 11, 2013
-- Description: Solves boolean satisfiability problem
--              using a brute force search.

module SatSolver (sat
                 ,SatIdentifier
                 ,SatExpr(..)
                 ,VarBinding
                 ,(&.)
                 ,(|.)
                 ,(-->))
    where

import Data.List  (find)

-- Variable identifier
type SatIdentifier = String

data SatExpr = T
             | F
             | Var     SatIdentifier
             | Or      SatExpr SatExpr
             | And     SatExpr SatExpr
             | Implies SatExpr SatExpr
             | Not     SatExpr

type VarBinding = (SatIdentifier, Bool)


-- Determines if a interpretation exists that can satisfy the given boolean expression.
sat :: [SatIdentifier] -> SatExpr -> Maybe [VarBinding]
sat vars expr =  -- Uses the fmap from the Maybe functor to propagate the any failure (i.e. Nothing) from find:
                fmap getBindings (find isSolvable [(satWithBindings expr selectedBindings, selectedBindings)
                                                   | selectedBindings <- allBindings vars])
    where
      -- Generates every possible binding combination for the given variables.
      allBindings :: [SatIdentifier] -> [[VarBinding]]
      allBindings []         = []
      allBindings [var]      = [[(var, True)], [(var, False)]]
      allBindings (var:vars) =    map (\xs -> (var, True):xs)  (allBindings vars)
                               ++ map (\xs -> (var, False):xs) (allBindings vars)

      varId :: VarBinding -> SatIdentifier
      varId       (x,_) = x

      -- These deal with the results generated by the list comprehension in the body of sat:
      isSolvable  :: (Bool, [VarBinding]) -> Bool
      isSolvable  (x,_) = x
      getBindings :: (Bool, [VarBinding]) -> [VarBinding]
      getBindings (_,y) = y

      implies p q = not p || q

      satWithBindings :: SatExpr -> [VarBinding] -> Bool
      satWithBindings T               bindings = True
      satWithBindings F               bindings = False
      satWithBindings (Var     v)     bindings = let Just binding = lookup v bindings
                                                 in binding
      satWithBindings (Or      e1 e2) bindings = satWithBindings e1 bindings || satWithBindings e2 bindings
      satWithBindings (And     e1 e2) bindings = satWithBindings e1 bindings && satWithBindings e2 bindings
      satWithBindings (Implies e1 e2) bindings = implies (satWithBindings e1 bindings)
                                                         (satWithBindings e2 bindings)
      satWithBindings (Not     e1)    bindings = not (satWithBindings e1 bindings)


-- Infix operators for convenience
(&.)  = And
(|.)  = Or
(-->) = Implies



-- *** Tests ***

satTest1 = sat vars (
                     (mon |. wed |. thu) &. (Not wed) &. (Not fri) &. ((Not tue) &. (Not thu))
                    )
    where vars                      = ["Mon", "Tue", "Wed", "Thu", "Fri"]
          [mon, tue, wed, thu, fri] = map Var vars

satTest2 = sat vars (
                     (x1 |. (Not x2) |. (Not x3)) &. ((Not x1) |. (Not x2) |. (Not x3))
                     &. (x2 |. x3) &. (x3 |. x4) &. (x3 |. (Not x4))
                    )
    where [x1, x2, x3, x4] = map (Var . ('x':)) (map show [1..4])
          vars             = map getVarId [x1,x2,x3,x4]
          getVarId (Var v) = v

satTest3 = sat vars (a &. (Not a))
    where vars = ["a"]
          a    = Var "a"

-- Test using builtin boolean operations
boolTest1 = (mon  || wed || thu) && (not wed) && (not fri) && ((not tue) && (not thu))
    where mon = True
          tue = True
          wed = False
          thu = False
          fri = False

boolTest2 = (x1 || (not x2) || (not x3)) && ((not x1) || (not x2) || (not x3))
                     && (x2 || x3) && (x3 || x4) && (x3 || (not x4))
    where x1 = True
          x2 = False
          x3 = True
          x4 = True

boolTest3 = False   -- No solution to "p and (not p)"

