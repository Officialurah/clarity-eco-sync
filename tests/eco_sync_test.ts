import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can create new initiative",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('eco-sync', 'create-initiative', [
        types.ascii("Ocean Cleanup"),
        types.ascii("Remove plastic from oceans"),
        types.uint(1000)
      ], deployer.address)
    ]);
    
    block.receipts[0].result.expectOk();
    assertEquals(block.receipts[0].result, types.ok(types.uint(0)));
  }
});

Clarinet.test({
  name: "Can join initiative and log contributions",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const participant = accounts.get('wallet_1')!;
    
    // Create initiative
    let block = chain.mineBlock([
      Tx.contractCall('eco-sync', 'create-initiative', [
        types.ascii("Tree Planting"),
        types.ascii("Plant trees in urban areas"),
        types.uint(100)
      ], deployer.address)
    ]);
    
    // Join initiative
    let joinBlock = chain.mineBlock([
      Tx.contractCall('eco-sync', 'join-initiative', [
        types.uint(0)
      ], participant.address)
    ]);
    
    joinBlock.receipts[0].result.expectOk();
    
    // Log contribution
    let contribBlock = chain.mineBlock([
      Tx.contractCall('eco-sync', 'log-contribution', [
        types.uint(0),
        types.uint(10)
      ], participant.address)
    ]);
    
    contribBlock.receipts[0].result.expectOk();
    
    // Check participant stats
    let statsBlock = chain.mineBlock([
      Tx.contractCall('eco-sync', 'get-participant-stats', [
        types.uint(0),
        types.principal(participant.address)
      ], participant.address)
    ]);
    
    let stats = statsBlock.receipts[0].result.expectOk().expectSome();
    assertEquals(stats.contributions, types.uint(10));
    assertEquals(stats['tokens-earned'], types.uint(1));
  }
});

Clarinet.test({
  name: "Cannot join initiative twice",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const participant = accounts.get('wallet_1')!;
    
    // Create and join initiative
    let setup = chain.mineBlock([
      Tx.contractCall('eco-sync', 'create-initiative', [
        types.ascii("River Cleanup"),
        types.ascii("Clean local rivers"),
        types.uint(100)
      ], deployer.address),
      Tx.contractCall('eco-sync', 'join-initiative', [
        types.uint(0)
      ], participant.address)
    ]);
    
    // Try to join again
    let block = chain.mineBlock([
      Tx.contractCall('eco-sync', 'join-initiative', [
        types.uint(0)
      ], participant.address)
    ]);
    
    block.receipts[0].result.expectErr(types.uint(102)); // err-already-exists
  }
});