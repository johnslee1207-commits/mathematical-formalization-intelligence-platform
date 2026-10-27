import M0.Benchmark

/-! M3 first proof slice: five independently mapped Lean/Mathlib cases. -/
namespace M3

theorem m3_01_and_comm (P Q : Prop) : P ∧ Q → Q ∧ P := by
  intro h
  exact ⟨h.2, h.1⟩

theorem m3_02_nat_add_zero (n : Nat) : n + 0 = n := by
  exact Nat.add_zero n

theorem m3_03_union_subset {α : Type*} {A B C : Set α} : A ⊆ C → B ⊆ C → A ∪ B ⊆ C := by
  intro hA hB x hx
  exact hx.elim (fun h => hA h) (fun h => hB h)

theorem m3_04_exists_add_one (n : Nat) : ∃ m : Nat, m = n + 1 := by
  exact ⟨n + 1, rfl⟩

theorem m3_05_le_refl (n : Nat) : n ≤ n := by
  exact le_rfl

end M3
