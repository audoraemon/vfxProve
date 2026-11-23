extends RefCounted
## Might gauge Task 1: the pool's numbers -- size, rate, paying, refilling, float drift, the Faith refill steps, the tier gauge.


static func run(t) -> void:
	var p := MightPool.make(6)
	t.check(p.value == 6.0, "make(6) starts full")
	t.near(p.rate(), 0.1, 0.0001, "make(6) rate is 0.1 a second")
	t.near(MightPool.make(16).rate(), 16.0 / 60.0, 0.0001, "make(16) rate is 16/60")

	t.check(p.pay(4.0), "pay(4) on 6 succeeds")
	t.near(p.value, 2.0, 0.0001, "pay(4) leaves 2")
	t.check(not p.pay(3.0), "pay(3) on 2 fails")
	t.near(p.value, 2.0, 0.0001, "a failed pay leaves 2")

	p.pay(2.0)
	p.advance(30.0)
	t.near(p.value, 3.0, 0.0001, "30 s from empty gives 3")
	p.advance(1000.0)
	t.near(p.value, 6.0, 0.0001, "advance clamps at capacity")

	var q := MightPool.make(6)
	q.pay(6.0)
	for i in 600:
		q.advance(0.1)
	t.check(q.can_pay(6.0), "600 x 0.1 s from empty can pay 6 (float drift)")

	t.near(MightPool.refill_for(0), 60.0, 0.0001, "refill_for(0) is 60")
	t.near(MightPool.refill_for(3), 45.0, 0.0001, "refill_for(3) is 45")
	t.near(MightPool.refill_for(99), 30.0, 0.0001, "refill_for(99) hits the floor")
	t.near(MightPool.make(6, 10.0).refill_seconds, 30.0, 0.0001, "make clamps seconds to the floor")

	t.check(int(MightPool.for_tier(1).capacity) == 6, "for_tier(1) holds 6")
	t.check(int(MightPool.for_tier(5).capacity) == 16, "for_tier(5) holds 16")

	var w := MightPool.make(6)
	w.value = 2.99
	t.check(w.whole() == 2, "whole() is 2 at 2.99")
	w.value = 2.99995
	t.check(w.whole() == 3, "whole() is 3 at 2.99995")

	var r := MightPool.make(6)
	r.pay(5.0)
	r.refill()
	t.check(r.value == 6.0, "refill() fills")
