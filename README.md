# 🏗 Fluid Salaries

## Inspiration
Sablier.finance, Superfluid and DeFi composability.

## What it does
It allows a payer and receiver to open a subscription stream exactly as can be done with Sablier.finance. As with Sablier the payment accrues to the receiver in realtime rather than bi-weekly or monthly as with traditional payroll.
The issue with a Sablier stream is that it requires the payor to lockup capital that could be otherwise be earning interest and the receiver to do constant transactions in order to allocate their received funds into yield bearing pools.
With Fluid Salaries the stream also is continuously invested into a AAVE lending pool as the value accrues to the receiver while also earning interest for the payor unlocking capital efficiency for all parties.

## How we built it
When a stream is created the funds are deposited into an AAVE pool and when the receiver withdraws the amount owed to them with interest is calculated and sent to the receiver.

## Challenges we ran into
Figuring out how to calculate onchain a constant sum being continuously invested and compounded in order to make sure both parties receive their fair share of the interest.

## Accomplishments that we're proud of
Implementing the calculation of the future value of a continuously compounding annuity due in solidity.

## What we learned
How AAVE pools calculates and partitions interest overtime. How to implement financial formulas that needs Eulers constant in solidity.

## What's next for Fluid Salaries
Get it to a production ready deployment for real world use.
