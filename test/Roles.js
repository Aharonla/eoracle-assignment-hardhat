const { loadFixture } = require('@nomicfoundation/hardhat-toolbox/network-helpers');
const { expect } = require('chai');
const { ethers, upgrades } = require('hardhat');
// const { utils } = require('ethers');
const { stringToHex, padLeft } = require('web3-utils');
const { encodeParameter } = require('web3-eth-abi');

describe("Roles", function () {
    async function setup() {
        const StakeManager = await ethers.getContractFactory('StakeManager');
        const roles = await upgrades.deployProxy(StakeManager);
        await roles.waitForDeployment();
        return { roles };
    }

    describe("GrantRole", function () {
        it("should revert when called externally", async function () {
            const { roles } = await loadFixture(setup);
            const [, user] = await ethers.getSigners();
            const role = padLeft(stringToHex("NEW_ROLE"), 64);
            await expect(roles.grantRole(role, user.address)).to.be.revertedWithCustomError(roles, "NoPublicGrantRole");
        });
    });

    describe("AddRole", function () {
        it("should add a new role", async function () {
            const { roles } = await loadFixture(setup);
            const role = padLeft(stringToHex("NEW_ROLE"), 64);
            expect(await roles.addRole(role)).to.emit(roles, 'RoleAdded').withArgs(role);
    });
    it("should revert if not admin", async function () {
        const { roles } = await loadFixture(setup);
        const [, user] = await ethers.getSigners();
        const role = padLeft(stringToHex("NEW_ROLE"), 64);
        await expect(roles.connect(user).addRole(role)).to.be.revertedWithCustomError(roles, "NotAdmin").withArgs(user.address);
    });
    it("should revert if role already exists", async function () {
        const { roles } = await loadFixture(setup);
        const role = padLeft(stringToHex("NEW_ROLE"), 64);
        await roles.addRole(role);
        await expect(roles.addRole(role)).to.be.revertedWithCustomError(roles, "RoleAllowed").withArgs(role);
    });

    describe("RemoveRole", function () {
        it("should remove a role", async function () {
            const { roles } = await loadFixture(setup);
            const role = padLeft(stringToHex("NEW_ROLE"), 64);
            await roles.addRole(role);
            expect(await roles.removeRole(role)).to.emit(roles, 'RoleRemoved').withArgs(role);
        });
        it("should revert if not admin", async function () {
            const { roles } = await loadFixture(setup);
            const [, user] = await ethers.getSigners();
            const role = padLeft(stringToHex("NEW_ROLE"), 64);
            await roles.addRole(role);
            await expect(roles.connect(user).removeRole(role)).to.be.revertedWithCustomError(roles, "NotAdmin").withArgs(user.address);
        });
        it("should revert if role does not exist", async function () {
            const { roles } = await loadFixture(setup);
            const role = padLeft(stringToHex("NEW_ROLE"), 64);
            await expect(roles.removeRole(role)).to.be.revertedWithCustomError(roles, "RoleNotAllowed").withArgs(role);
        });
    });
});
})