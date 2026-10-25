import M0.Benchmark

/-! M1 first proof slice: five Lean/Mathlib formalization cases. -/
namespace M1

theorem m1_01_imp_trans (P Q R : Prop) : (P → Q) → (Q → R) → P → R := by
  intro hPQ hQR hP
  exact hQR (hPQ hP)

theorem m1_02_even_mul_two (n : Nat) : Even (2 * n) := by
  exact ⟨n, by omega⟩

theorem m1_03_sub_self (n : Nat) : n - n = 0 := by
  exact Nat.sub_self n

theorem m1_04_inter_subset_left {α : Type*} {A B : Set α} : A ∩ B ⊆ A := by
  intro x hx
  exact hx.1

theorem m1_05_exists_eq_self (α : Type*) [Nonempty α] : ∃ x : α, x = x := by
  let x : α := Classical.choice (inferInstance : Nonempty α)
  exact ⟨x, rfl⟩

end M1

