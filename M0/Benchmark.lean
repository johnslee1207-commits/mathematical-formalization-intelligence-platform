import Mathlib

/-! M0 ten-problem Lean/Mathlib formalization benchmark. -/
namespace M0

/- M0-01: conjunction elimination. -/
theorem m0_01_and_left (P Q : Prop) : P ∧ Q → P := by
  intro h
  exact h.1

/- M0-02: classical double-negation elimination. -/
theorem m0_02_dne (P : Prop) : ¬¬P → P := by
  classical
  tauto

/- M0-03: the sum of two even naturals is even. -/
theorem m0_03_even_add_even {a b : Nat} : Even a → Even b → Even (a + b) := by
  rintro ⟨x, hx⟩ ⟨y, hy⟩
  refine ⟨x + y, ?_⟩
  omega

/- M0-04: 3 divides 12. -/
theorem m0_04_three_dvd_twelve : (3 : Nat) ∣ 12 := by
  norm_num

/- M0-05: addition is monotone on naturals. -/
theorem m0_05_add_le_add_right {a b : Nat} : a ≤ b → ∀ c, a + c ≤ b + c := by
  intro h c
  exact Nat.add_le_add_right h c

/- M0-06: sum of the first n naturals. -/
theorem m0_06_sum_range_id (n : Nat) :
    (∑ i ∈ Finset.range n, i) = n * (n - 1) / 2 := by
  exact Finset.sum_range_id n

/- M0-07: subset inclusion is transitive. -/
theorem m0_07_subset_trans {α : Type*} {A B C : Set α} :
    A ⊆ B → B ⊆ C → A ⊆ C := by
  intro hAB hBC x hx
  exact hBC (hAB hx)

/- M0-08: image cardinality does not exceed source cardinality. -/
theorem m0_08_card_image_le {α β : Type*} [DecidableEq β] (f : α → β) (s : Finset α) :
    (s.image f).card ≤ s.card := by
  exact Finset.card_image_le

/- M0-09: left multiplication by the group identity. -/
theorem m0_09_one_mul (G : Type*) [Group G] (x : G) : 1 * x = x := by
  exact one_mul x

/- M0-10: a deliberately contradictory hypothesis. -/
theorem m0_10_not_forall_succ_le (h : ∀ n : Nat, n + 1 ≤ n) : False := by
  have h0 := h 0
  omega

end M0
