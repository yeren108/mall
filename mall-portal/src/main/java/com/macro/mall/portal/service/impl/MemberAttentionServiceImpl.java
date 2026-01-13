package com.macro.mall.portal.service.impl;

import com.macro.mall.mapper.PmsBrandMapper;
import com.macro.mall.model.PmsBrand;
import com.macro.mall.model.UmsMember;
import com.macro.mall.portal.domain.MemberBrandAttention;
import com.macro.mall.portal.repository.MemberBrandAttentionRepository;
import com.macro.mall.portal.service.MemberAttentionService;
import com.macro.mall.portal.service.UmsMemberService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.Date;

/**
 * 会员关注Service实现类
 * Created by macro on 2018/8/2.
 */
@Service
public class MemberAttentionServiceImpl implements MemberAttentionService {

    private static final Logger LOG = LoggerFactory.getLogger(MemberAttentionServiceImpl.class);

    @Value("${mongo.insert.sqlEnable}")
    private Boolean sqlEnable;
    @Autowired
    private PmsBrandMapper brandMapper;
    @Autowired
    private MemberBrandAttentionRepository memberBrandAttentionRepository;
    @Autowired
    private UmsMemberService memberService;

    @Override
    public int add(MemberBrandAttention memberBrandAttention) {
        try {
            int count = 0;
            if(memberBrandAttention.getBrandId()==null){
                return 0;
            }
            UmsMember member = memberService.getCurrentMember();
            memberBrandAttention.setMemberId(member.getId());
            memberBrandAttention.setMemberNickname(member.getNickname());
            memberBrandAttention.setMemberIcon(member.getIcon());
            memberBrandAttention.setCreateTime(new Date());
            MemberBrandAttention findAttention = memberBrandAttentionRepository.findByMemberIdAndBrandId(memberBrandAttention.getMemberId(), memberBrandAttention.getBrandId());
            if (findAttention == null) {
                if(sqlEnable){
                    PmsBrand brand = brandMapper.selectByPrimaryKey(memberBrandAttention.getBrandId());
                    if(brand==null){
                        return 0;
                    }else{
                        memberBrandAttention.setBrandCity(null);
                        memberBrandAttention.setBrandName(brand.getName());
                        memberBrandAttention.setBrandLogo(brand.getLogo());
                    }
                }
                memberBrandAttentionRepository.save(memberBrandAttention);
                count = 1;
            }
            return count;
        } catch (Exception e) {
            LOG.warn("MongoDB不可用，添加关注失败: {}", e.getMessage());
            return 0;
        }
    }

    @Override
    public int delete(Long brandId) {
        try {
            UmsMember member = memberService.getCurrentMember();
            return memberBrandAttentionRepository.deleteByMemberIdAndBrandId(member.getId(),brandId);
        } catch (Exception e) {
            LOG.warn("MongoDB不可用，删除关注失败: {}", e.getMessage());
            return 0;
        }
    }

    @Override
    public Page<MemberBrandAttention> list(Integer pageNum, Integer pageSize) {
        try {
            UmsMember member = memberService.getCurrentMember();
            Pageable pageable = PageRequest.of(pageNum-1,pageSize);
            return memberBrandAttentionRepository.findByMemberId(member.getId(),pageable);
        } catch (Exception e) {
            LOG.warn("MongoDB不可用，获取关注列表失败: {}", e.getMessage());
            return Page.empty();
        }
    }

    @Override
    public MemberBrandAttention detail(Long brandId) {
        try {
            UmsMember member = memberService.getCurrentMember();
            return memberBrandAttentionRepository.findByMemberIdAndBrandId(member.getId(), brandId);
        } catch (Exception e) {
            LOG.warn("MongoDB不可用，获取关注详情失败: {}", e.getMessage());
            return null;
        }
    }

    @Override
    public void clear() {
        try {
            UmsMember member = memberService.getCurrentMember();
            memberBrandAttentionRepository.deleteAllByMemberId(member.getId());
        } catch (Exception e) {
            LOG.warn("MongoDB不可用，清空关注失败: {}", e.getMessage());
        }
    }
}
