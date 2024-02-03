const { loadFixture } = require('@nomicfoundation/hardhat-toolbox/network-helpers');
const { expect } = require('chai');
const { ethers, upgrades } = require('hardhat');

describe('StakeManager', function () {
    async function setup() {
        const StakeManager = await ethers.getContractFactory('StakeManager');
        const stakeManager = await upgrades.deployProxy(StakeManager);
        await stakeManager.waitForDeployment();
        return { stakeManager };
    }

    describe("Upgrade", function () {
        it("should upgrade", async function () {
            let { stakeManager } = await setup();
            const StakeManagerV2 = await ethers.getContractFactory('StakeManagerV2');
            stakeManager = await upgrades.upgradeProxy(await stakeManager.getAddress(), StakeManagerV2);
            expect(await stakeManager.setConfiguration(100, 3600)).to.emit(stakeManager, 'FakeEvent');
        });
    })

    describe('SetConfiguration', function () {
        it('should set correct configurations', async function () {
            const { stakeManager } = await setup();
            const amount = 100;
            const time = 3600;
            expect(
                await stakeManager.setConfiguration(amount, time)
                ).to.emit(stakeManager, 'SetConfiguration')
                .withArgs(amount, time);
        });

        it("should revert if not admin", async function () {
            const { stakeManager } = await loadFixture(setup);
            const [, user] = await ethers.getSigners();
            const amount = 100;
            const time = 3600;
            // await stakeManager.connect(user).setConfiguration(amount, time);
            await expect(
                stakeManager.connect(user).setConfiguration(amount, time)
            ).to.be.revertedWithCustomError(stakeManager, "NotAdmin")
            .withArgs(user.address);
        });
    });
});