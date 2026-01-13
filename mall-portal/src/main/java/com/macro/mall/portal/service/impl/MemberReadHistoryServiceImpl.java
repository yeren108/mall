package com.macro.mall.portal.service.impl;

import com.macro.mall.mapper.PmsProductMapper;
import com.macro.mall.model.PmsProduct;
import com.macro.mall.model.UmsMember;
import com.macro.mall.portal.domain.MemberReadHistory;
import com.macro.mall.portal.repository.MemberReadHistoryRepository;
import com.macro.mall.portal.service.MemberReadHistoryService;
import com.macro.mall.portal.service.UmsMemberService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;

/**
 * 会员浏览记录管理Service实现类
 * Created by macro on 2018/8/3.
 */
@Service
public class MemberReadHistoryServiceImpl implements MemberReadHistoryService {

    private static final Logger LOG = LoggerFactory.getLogger(MemberReadHistoryServiceImpl.class);

    @Value("${mongo.insert.sqlEnable}")
    private Boolean sqlEnable;
    @Autowired
    private PmsProductMapper productMapper;
    @Autowired
    private MemberReadHistoryRepository memberReadHistoryRepository;
    @Autowired
    private UmsMemberService memberService;
    @Override
    public int create(MemberReadHistory memberReadHistory) {
        try {
            if (memberReadHistory.getProductId() == null) {
                return 0;
            }
            UmsMember member = memberService.getCurrentMember();
            memberReadHistory.setMemberId(member.getId());
            memberReadHistory.setMemberNickname(member.getNickname());
            memberReadHistory.setMemberIcon(member.getIcon());
            memberReadHistory.setId(null);
            memberReadHistory.setCreateTime(new Date());
            if (sqlEnable) {
                PmsProduct product = productMapper.selectByPrimaryKey(memberReadHistory.getProductId());
                if (product == null || product.getDeleteStatus() == 1) {
                    return 0;
                }
                memberReadHistory.setProductName(product.getName());
                memberReadHistory.setProductSubTitle(product.getSubTitle());
                memberReadHistory.setProductPrice(product.getPrice() + "");
                memberReadHistory.setProductPic(product.getPic());
            }
            memberReadHistoryRepository.save(memberReadHistory);
            return 1;
        } catch (Exception e) {
            LOG.warn("MongoDB不可用，创建浏览记录失败: {}", e.getMessage());
            return 0;
        }
    }

    @Override
    public int delete(List<String> ids) {
        try {
            List<MemberReadHistory> deleteList = new ArrayList<>();
            for(String id:ids){
                MemberReadHistory memberReadHistory = new MemberReadHistory();
                memberReadHistory.setId(id);
                deleteList.add(memberReadHistory);
            }
            memberReadHistoryRepository.deleteAll(deleteList);
            return ids.size();
        } catch (Exception e) {
            LOG.warn("MongoDB不可用，删除浏览记录失败: {}", e.getMessage());
            return 0;
        }
    }

    @Override
    public Page<MemberReadHistory> list(Integer pageNum, Integer pageSize) {
        try {
            UmsMember member = memberService.getCurrentMember();
            Pageable pageable = PageRequest.of(pageNum-1, pageSize);
            return memberReadHistoryRepository.findByMemberIdOrderByCreateTimeDesc(member.getId(),pageable);
        } catch (Exception e) {
            LOG.warn("MongoDB不可用，返回空浏览记录列表: {}", e.getMessage());
            // 返回空的Page对象
            return Page.empty();
        }
    }

    @Override
    public void clear() {
        try {
            UmsMember member = memberService.getCurrentMember();
            memberReadHistoryRepository.deleteAllByMemberId(member.getId());
        } catch (Exception e) {
            LOG.warn("MongoDB不可用，清空浏览记录失败: {}", e.getMessage());
        }
    }
}
